extern crate verilated;
extern crate verilated_module;

use single_value_channel::{channel_starting_with, Updater};
use softbuffer::GraphicsContext;
use std::sync::mpsc::{channel, Receiver};
use std::thread;
use std::time::{Duration, Instant};
use winit::dpi::{PhysicalPosition, PhysicalSize};
use winit::event::{Event, WindowEvent};
use winit::event_loop::{ControlFlow, EventLoop};
use winit::window::WindowBuilder;

use verilated_module::module;

#[module(top)]
pub struct Top {
    #[port(clock)]
    pub clk: bool,
    #[port(output)]
    pub clk_65_536khz: bool,

    #[port(input)]
    pub reset_n: bool,

    #[port(output)]
    pub vsync: bool,
    #[port(output)]
    pub hsync: bool,
    #[port(output)]
    pub de: bool,
    #[port(output)]
    pub rgb: [bool; 24],

    int_clk_en: bool,
    int_clk_2x_en: bool,
}

impl Top {
    fn edge_eval(&mut self) {
        self.clock_toggle();
        self.eval();
    }

    fn cycle(&mut self) -> bool {
        self.edge_eval();
        self.edge_eval();

        self.clk_65_536khz() == 1
    }

    fn cycle_one_65khz(&mut self, i: u64) {
        while self.clk_65_536khz() == 0 {
            // Clock until 65kHz goes high
            self.edge_eval();
        }

        // Trace this timestamp
        self.log_state(i, false);

        while self.clk_65_536khz() == 1 {
            // Clock until 65kHz goes low
            self.edge_eval();
        }

        // Trace this timestamp
        self.log_state(i, true);
    }

    fn trace(&mut self, rate: u64, cycle: u64, falling_edge: bool) {
        let addend = if falling_edge { 1 } else { 0 };
        self.trace_at(Duration::from_nanos(rate * ((2 * cycle) + addend)));
    }

    fn log_state(&mut self, cycle: u64, falling_edge: bool) {
        self.trace(15259, cycle, falling_edge);
    }

    fn log_full_rate_state(&mut self, cycle: u64, falling_edge: bool) {
        self.trace(153, cycle, falling_edge);
    }
}

#[derive(Clone)]
struct Frame {
    data: Vec<u32>,
    id: u64,
}

enum TBEvent {
    Quit,
    StartPause,
}

// const HEIGHT: usize = 228;
const HEIGHT: usize = 720;
const WIDTH: usize = HEIGHT;

fn create_tb_processor(buffer_transmitter: Updater<Frame>, event_receiver: Receiver<TBEvent>) {
    thread::spawn(move || {
        let mut tb = Top::default();
        // tb.open_trace("trace.vcd", 99).unwrap();

        let mut cycle_counter: u64 = 0;

        // Initialize core
        while cycle_counter < 4 {
            tb.cycle_one_65khz(cycle_counter);

            cycle_counter += 1;
        }

        tb.set_reset_n(1);

        // Wait for start event
        loop {
            match event_receiver.try_recv() {
                Ok(TBEvent::StartPause) => {
                    break;
                }
                // Purposefully ignore errors, because channel might not be open yet
                _ => {}
            }
        }

        let mut next_frame_buffer: Vec<u32> = vec![0; HEIGHT * WIDTH];
        let mut frame_id = 1;
        let mut has_first_pixel_of_frame = false;
        let mut next_frame_pixel_x = 0;
        let mut next_frame_pixel_y = 0;

        let mut last_tick_did_log_high = false;

        loop {
            // Run one 60Hz tick
            let mut did_vsync = false;
            while !did_vsync {
                let clk_is_high = tb.cycle();
                if !last_tick_did_log_high && clk_is_high {
                    // 65kHz clock rose
                    tb.log_state(cycle_counter, false);
                    last_tick_did_log_high = true;
                } else if last_tick_did_log_high && !clk_is_high {
                    // 65kHz clock fell
                    tb.log_state(cycle_counter, true);
                    last_tick_did_log_high = false;
                    cycle_counter += 1;
                }

                if tb.de() == 1 {
                    // Pixel enabled, write to buffer
                    has_first_pixel_of_frame = true;
                    if next_frame_pixel_x >= WIDTH {
                        println!("ERROR: Saw out of bounds pixel at X: {next_frame_pixel_x}, Y: {next_frame_pixel_y}");
                    } else if next_frame_pixel_y >= HEIGHT {
                        println!("ERROR: Saw out of bounds pixel at Y: {next_frame_pixel_y}, X: {next_frame_pixel_x}");
                    } else {
                        next_frame_buffer[next_frame_pixel_y * WIDTH + next_frame_pixel_x] =
                            tb.rgb();
                    }

                    next_frame_pixel_x += 1;
                }

                if tb.hsync() == 1 {
                    next_frame_pixel_x = 0;

                    if has_first_pixel_of_frame {
                        // Only leave y = 0 once we've seen a pixel
                        next_frame_pixel_y += 1;
                    }
                }

                if tb.vsync() == 1 {
                    next_frame_pixel_x = 0;
                    next_frame_pixel_y = 0;
                    has_first_pixel_of_frame = false;

                    did_vsync = true;
                }
            }

            match event_receiver.try_recv() {
                Ok(event) => match event {
                    TBEvent::Quit => {
                        // Close connection
                        tb.finish();
                        return;
                    }
                    TBEvent::StartPause => {
                        // TODO
                    }
                    _ => {}
                },
                _ => {}
            }

            // Send latest buffer
            // println!("Frame {frame_id} available, sending");
            buffer_transmitter
                .update(Frame {
                    data: next_frame_buffer.clone(),
                    id: frame_id,
                })
                .unwrap();

            frame_id += 1;
        }
    });
}

pub fn main() {
    let mut last_frame_id = 0;

    let (mut buffer_receiver, buffer_transmitter) = channel_starting_with::<Frame>(Frame {
        data: vec![0; HEIGHT * WIDTH],
        id: last_frame_id,
    });
    let (event_transmitter, event_receiver) = channel::<TBEvent>();

    create_tb_processor(buffer_transmitter, event_receiver);

    // Window management
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_inner_size(PhysicalSize::new(WIDTH as u32, HEIGHT as u32))
        .build(&event_loop)
        .unwrap();
    let mut graphics_context = unsafe { GraphicsContext::new(&window, &window) }.unwrap();

    let mut last_timestamp = Instant::now();

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Poll;

        let latest_frame = buffer_receiver.latest();
        if latest_frame.id != last_frame_id {
            last_frame_id = latest_frame.id;
            window.request_redraw();
        }

        match event {
            Event::RedrawRequested(window_id) if window_id == window.id() => {
                let current_timestamp = Instant::now();
                let difference = current_timestamp.checked_duration_since(last_timestamp);
                last_timestamp = current_timestamp;

                // println!("Rendering window after {difference:?}");

                graphics_context.set_buffer(
                    &buffer_receiver.latest().data,
                    WIDTH as u16,
                    HEIGHT as u16,
                );
            }
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                window_id,
            } if window_id == window.id() => {
                *control_flow = ControlFlow::Exit;
                event_transmitter.send(TBEvent::Quit).unwrap();
            }
            Event::WindowEvent {
                window_id,
                event:
                    WindowEvent::KeyboardInput {
                        device_id: _,
                        input,
                        is_synthetic: _,
                    },
            } => {
                if window_id == window.id() {
                    match input.virtual_keycode {
                        Some(winit::event::VirtualKeyCode::Space) => {
                            let _ = event_transmitter.send(TBEvent::StartPause);
                        }
                        Some(winit::event::VirtualKeyCode::Escape) => {
                            *control_flow = ControlFlow::Exit;
                            event_transmitter.send(TBEvent::Quit).unwrap();
                        }
                        _ => {}
                    }
                }
            }
            _ => {}
        }
    });
}
