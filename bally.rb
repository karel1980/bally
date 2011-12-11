require 'gtk2'

class Bally
  attr_accessor :images,:tiles,:height,:width,:steps,:pb,:drawingarea,:gc,:gridwidth,:gridheight

  def initialize()
    @width=800
    @height=600
    @gridwidth=10
    @gridheight=10

    @images={}
    @steps=25
    puts "Preloading images"
    (0..@steps).each { |i|
      name="xspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
      name="yspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
    }

    build_ui()
  end

  def build_ui
    @window=window=Gtk::Window.new
    window.set_title("Bally")
    window.border_width=10
    window.show_all
    window.set_size_request(width, height)

    window.signal_connect("destroy") {
      Gtk.main_quit
    }

    @drawingarea=Gtk::DrawingArea.new
    window.add(@drawingarea)
    @drawingarea.set_size_request(width, height)
    @gc=Gdk::GC.new(@drawingarea.window)

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
    return [ x_offset + (0.5 + x) * @width / @gridwidth, y_offset + (0.5 + y) * @height / @gridwidth ]
  end
  def gridsize
    @width > @height ? @height : @width
  end
  
  def draw_grid()
    @gc.foreground=Gdk::Color.new(0,0,0)
    (0..@gridwidth).each { |i|
      @drawingarea.window.draw_line(gc, x_offset + i*width/gridwidth, y_offset, x_offset + i*width/gridwidth, y_offset+height)
    }
    (0..@gridheight).each { |i|
      @drawingarea.window.draw_line(gc, x_offset, y_offset + i*height/gridheight, x_offset + width/gridheight, y_offset+ + i*height/gridheight)
    }
  end

  def start

    @balls=[]

    area=drawingarea
    area.add_events(Gdk::Event::BUTTON_PRESS_MASK)
    area.signal_connect("button-press-event") { |e,d|
      @balls << Ball.new(0,5,self)
    }
    
    @grid=[]
    10.times { @grid << Array.new(10) }

    Gtk.timeout_add(30) {
      update_positions()
      update_graphics()
      true
    }

    @window.show_all
    Gtk.main
  end

  def update_positions
    @balls.each { |ball| ball.update self }
    @balls.delete_if { |ball| not ball.keep? }
  end

  def update_graphics
    draw_grid()
    @balls.each_with_index { |ball,idx|
      ball.draw self
    }
  end
end

class Ball
  attr_accessor :x,:y

  def initialize(x,y,ctx)
    @x=x
    @y=y
    @direction=[1,0]
    @step=0
    @kleur=0

    puts "x = #{x}"
    puts "y = #{y}"
  end
  
  def draw(ctx)
    gridpos1=ctx.gridpos(@x, @y)
    gridpos2=ctx.gridpos(@x + @direction[0], @y + @direction[1])
    @direction == [1,0] and imgname="yspin%02d"%(ctx.steps-@step)
    @direction == [-1,0] and imgname="yspin%02d"%(@step)
    @direction == [0,1] and imgname="xspin%02d"%(ctx.steps-@step)
    @direction == [0,-1] and imgname="xspin%02d"%(@step)
    pb=ctx.images[imgname]
    gx = gridpos1[0] + (gridpos2[0]-gridpos1[0]) * @step/ctx.steps - pb.width/2
    gy = gridpos1[1] + (gridpos2[1]-gridpos1[1]) * @step/ctx.steps - pb.height/2
    ctx.drawingarea.window.draw_pixbuf(ctx.gc, pb, 0, 0, gx, gy, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
  end

  def update(ctx)
    @step+=1
    if @step>=ctx.steps
      @step=0
      @x+=@direction[0]
      @y+=@direction[1]
      puts "new ball position is #{@x},#{@y}"
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

