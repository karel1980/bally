require 'gtk2'

class Bally
  attr_accessor :images,:tiles,:height,:width,:steps,:pb,:drawingarea,:gc,:gridwidth,:gridheight,:grid

  def initialize()
    @width=800
    @height=600
    @gridwidth=10
    @gridheight=10
    @expired_balls=[]

    @grid=[]
    @gridwidth.times { @grid << Array.new(gridheight) }
    @grid[3][5]=[0,-1]
    @grid[3][2]=[1,0]
    @grid[6][2]=[0,1]

    @images={}
    @steps=25
    puts "Preloading images"
    (0..@steps).each { |i|
      name="xspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
      name="yspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
    }
    ["up","down","left","right"].each { |name|
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
    @drawingarea.set_size_request(levelsize[0], levelsize[1])
    @gc=Gdk::GC.new(@drawingarea.window)

    puts x_offset, y_offset
  end

  def x_offset()
    return 0 if @height >= @width
    return (@width - @height) / 2
  end
  def y_offset()
    return 0 if @height <= @width
    return (@height - @width) / 2
  end

  def gridcenter(x,y)
    return [ x_offset + (0.5 + x) * levelsize[0] / @gridwidth, y_offset + (0.5 + y) * levelsize[1] / @gridheight ]
  end

  def draw_grid()
    @gc.foreground=Gdk::Color.new(0,0,0)
    w,h = levelsize
    # Draw vertical lines
    (0..@gridwidth).each { |i|
      @drawingarea.window.draw_line(gc, x_offset + i*w/gridwidth, y_offset, x_offset + i*w/gridwidth, y_offset+h)
    }
    # Draw horizontal lines
    (0..@gridheight).each { |i|
      @drawingarea.window.draw_line(gc, x_offset, y_offset + i*h/gridheight, x_offset + w, y_offset+ + i*h/gridheight)
    }
  end

  # returns a multiple of the grid's size
  # which fits snugly in the available drawingarea
  def levelsize
    if (gridwidth * width > gridheight * height)
      return [width, width * gridheight / gridwidth]
    else
      return [height * gridwidth / gridheight, height]
    end
  end

  def start

    @balls=[]

    area=drawingarea
    area.add_events(Gdk::Event::BUTTON_PRESS_MASK)
    area.signal_connect("button-press-event") { |e,d|
      @balls << Ball.new(0,5,self)
    }
    
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
    @balls -= @expired_balls
    @expired_balls.clear
  end

  def update_graphics
    #TODO:clear the drawingarea (which is already double buffered IIUC)

    draw_grid()
    draw_arrows()
    @balls.each_with_index { |ball,idx|
      ball.draw self
    }
  end

  def draw_arrows()
    @gridwidth.times { |row|
      @gridheight.times { |col|
        dir=@grid[row][col]
        if dir
          center = gridcenter(row,col)
          pb = images[arrow_image dir]
          gx = center[0] - pb.width/2
          gy = center[1] - pb.height/2
          drawingarea.window.draw_pixbuf(gc, pb, 0, 0, gx, gy, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
        end
      }
    }
  end

  def arrow_image(dir)
    return "up" if dir[1]==-1
    return "down" if dir[1]==1
    return "left" if dir[0]==-1
    return "right" if dir[0]==1
  end

  def ball_expired(ball)
    @expired_balls << ball
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
    gridcenter1=ctx.gridcenter(@x, @y)
    gridcenter2=ctx.gridcenter(@x + @direction[0], @y + @direction[1])
    @direction == [1,0] and imgname="yspin%02d"%(ctx.steps-@step)
    @direction == [-1,0] and imgname="yspin%02d"%(@step)
    @direction == [0,1] and imgname="xspin%02d"%(ctx.steps-@step)
    @direction == [0,-1] and imgname="xspin%02d"%(@step)
    pb=ctx.images[imgname]
    gx = gridcenter1[0] + (gridcenter2[0]-gridcenter1[0]) * @step/ctx.steps - pb.width/2
    gy = gridcenter1[1] + (gridcenter2[1]-gridcenter1[1]) * @step/ctx.steps - pb.height/2
    ctx.drawingarea.window.draw_pixbuf(ctx.gc, pb, 0, 0, gx, gy, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
  end

  def update(ctx)
    @step+=1
    if @step>=ctx.steps
      @step=0
      @x+=@direction[0]
      @y+=@direction[1]
      puts "new ball position is #{@x},#{@y}"

      if @x < 0 || @x >= ctx.gridwidth || @y < 0 || @y >= ctx.gridheight
        ctx.ball_expired(self)
      elsif ctx.grid[x][y]
        @direction=ctx.grid[x][y]
      end
    end
  end

end


bally=Bally.new
bally.start()

