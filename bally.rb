require 'gtk2'

class GameContext
  attr_accessor :images,:tiles,:height,:width

  def initialize()
    @images={}
    @tiles=[10,10]
    @height=600
    @width=800
  end

  def x_offset()
    return 0 if @height >= @width
    return (@width - @height) / 2
  end
  def y_offset()
    return 0 if @height <= @width
    return (@height - @width) / 2
  end

  def gridpos(x,y)
    return [ x_offset + (0.5 + x) * (@width / 10), y_offset + (0.5 + y) * (@height / 10) ]
  end
  def gridsize
    @width > @height ? @height : @width
  end
  
end

class Bally
  def initialize
  end

  def start
    @ctx = GameContext.new
    puts "Preloading images"
    (0..10).each { |i|
      name="xspin%02d"%i
      @ctx.images[name] = Gdk::Pixbuf.new("images/#{name}.png")
      name="yspin%02d"%i
      @ctx.images[name] = Gdk::Pixbuf.new("images/#{name}.png")
    }
    window=Gtk::Window.new
    window.signal_connect("destroy") {
      Gtk.main_quit
    }

    window.set_title("Bally")
    window.border_width=10
    window.show_all
    window.set_size_request(@ctx.width, @ctx.height)

    @balls=[]
    @drawingarea=Gtk::DrawingArea.new
    @drawingarea.set_size_request(400, 400)
    @drawingarea.add_events(Gdk::Event::BUTTON_PRESS_MASK)
    @drawingarea.signal_connect("button-press-event") { |e,d|
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
    @balls.delete_if { |ball| not ball.keep? }
  end

  def update_graphics
    gc=Gdk::GC.new(@drawingarea.window)
    gc.foreground=Gdk::Color.new(0,0,0)
    @drawingarea.window.draw_rectangle(gc, false, @ctx.x_offset, @ctx.y_offset, @ctx.gridsize, @ctx.gridsize)
    gc.foreground=Gdk::Color.new(255,255,255)
    @balls.each_with_index { |ball,idx|
      ball.draw(@ctx,gc,@drawingarea.window)
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
  
  def draw(ctx, gc, drawable)
    gridpos1=ctx.gridpos(@x, @y)
    gridpos2=ctx.gridpos(@x + @direction[0], @y + @direction[1])
    @direction == [1,0] and imgname="yspin%02d"%(@step)
    @direction == [-1,0] and imgname="yspin%02d"%(10-@step)
    @direction == [0,1] and imgname="xspin%02d"%(@step)
    @direction == [0,-1] and imgname="xspin%02d"%(10-@step)
    pb=ctx.images[imgname]
    gx = gridpos1[0] + (gridpos2[0]-gridpos1[0]) * @step/10 - pb.width/2
    gy = gridpos1[1] + (gridpos2[1]-gridpos1[1]) * @step/10 - pb.height/2
    drawable.draw_pixbuf(gc, pb, 0, 0, gx, gy, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
  end

  def update()
    @step+=1
    if @step>=10
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

