extern crate verilated;
extern crate verilated_module;

use softbuffer::GraphicsContext;
use std::time::Duration;
use winit::dpi::PhysicalSize;
use winit::event::{Event, WindowEvent};
use winit::event_loop::{ControlFlow, EventLoop};
use winit::window::WindowBuilder;

use verilated_module::module;

#[module(top)]
pub struct Top {
    #[port(clock)]
    pub clk: bool,

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
    fn cycle_eval(&mut self, i: u64) {
        self.clock_toggle();
        self.eval();
        self.trace_at(Duration::from_nanos(15 * 2 * i));

        self.clock_toggle();
        self.eval();
        self.trace_at(Duration::from_nanos(15 * ((2 * i) + 1)));
    }
}

pub fn main() {
    let mut tb = Top::default();
    tb.open_trace("trace.vcd", 99).unwrap();

    let mut cycle_counter: u64 = 0;

    while cycle_counter < 3000 {
        tb.cycle_eval(cycle_counter);

        cycle_counter += 1;
    }

    tb.set_reset_n(1);

    let height = 720;
    let width = 720;

    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_inner_size(PhysicalSize::new(width as u32, height as u32))
        .build(&event_loop)
        .unwrap();
    let mut graphics_context = unsafe { GraphicsContext::new(&window, &window) }.unwrap();

    let mut next_frame_buffer: Vec<u32> = vec![0; height * width];
    let mut has_first_pixel_of_frame = false;
    let mut next_frame_pixel_x = 0;
    let mut next_frame_pixel_y = 0;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        // Run one 60Hz tick
        for _ in 0..546134 {
            tb.cycle_eval(cycle_counter);

            if tb.de() == 1 {
                // Pixel enabled, write to buffer
                has_first_pixel_of_frame = true;
                if next_frame_pixel_x >= width {
                    println!("ERROR: Saw out of bounds pixel at X: {next_frame_pixel_x}, Y: {next_frame_pixel_y}");
                } else if next_frame_pixel_y >= height {
                    println!("ERROR: Saw out of bounds pixel at Y: {next_frame_pixel_y}, X: {next_frame_pixel_x}");
                } else {
                    next_frame_buffer[next_frame_pixel_y * width + next_frame_pixel_x] = tb.rgb();
                    next_frame_pixel_x += 1;
                }
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
            }

            cycle_counter += 1;
        }

        match event {
            Event::RedrawRequested(window_id) if window_id == window.id() => {
                graphics_context.set_buffer(&next_frame_buffer, width as u16, height as u16);
            }
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                window_id,
            } if window_id == window.id() => {
                *control_flow = ControlFlow::Exit;

                tb.finish();
            }
            _ => {}
        }
    });
}
