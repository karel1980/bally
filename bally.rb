require 'gtk2'

class Bally
  def initialize
  end

  def start
    window=Gtk::Window.new
    window.signal_connect("destroy") {
      Gtk.main_quit
    }

    window.set_title("Bally")
    window.border_width=10
    window.show_all
    window.set_size_request(640, 480)

    @balls=[]
    @drawingarea=Gtk::DrawingArea.new
    @drawingarea.set_size_request(400, 400)
    @drawingarea.add_events(Gdk::Event::BUTTON_PRESS_MASK)
    @drawingarea.signal_connect("button-press-event") { |e,d|
      puts "handling click"
      @balls << Ball.new(0,5)
    }
    
    window.add(@drawingarea)

    @grid=[]
    10.times { @grid << Array.new(10) }

    Gtk.timeout_add(10) {
      update_positions()
      update_graphics()
      true
    }

    window.show_all
    Gtk.main
  end

  def update_positions
    @balls.each { |ball| ball.update }
    @balls.each do |ball|
      puts ball.x
      puts ball.y
      puts ball.keep?
    end
    @balls.delete_if { |ball| not ball.keep? }
  end

  def update_graphics
    gc=Gdk::GC.new(@drawingarea.window)
    gc.foreground=Gdk::Color.new(0,0,0)
    @drawingarea.window.draw_rectangle(gc, true, 0, 0, 100, 100)
    gc.foreground=Gdk::Color.new(255,255,255)
    @balls.each_with_index { |ball,idx|
      ball.draw(gc,@drawingarea.window)
    }
  end
  def tell_time
    puts "the time is ..."
  end
end

class Ball
  attr_accessor :x,:y

  def initialize(x,y)
    @x=x
    @y=y
    @direction=[1,0]
    @step=0
    @kleur=0
  end
  
  def draw(gc, drawable)
    gx = 20 * (0.5 + @x + @step*@direction[0])
    gy = 20 * (0.5 + @y + @step*@direction[1])
    drawable.draw_rectangle(gc, true, gx-5, gy-5, 10, 10)
  end

  def update()
    @step+=0.1
    if @step>=1
      @step=0
      @x+=@direction[0]
      @y+=@direction[1]
      #TODO:if the ball is on an arrow tile,
      #change @direction
    end
  end

  def keep?
    return (@x>=0 and @y>=0 and @x<=10 and @y<=10)
  end

end

bally=Bally.new
bally.start()

