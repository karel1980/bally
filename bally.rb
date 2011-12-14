require 'gtk2'

class Direction
  attr_accessor :x,:y,:name
  def initialize(x,y, name)
    @x=x
    @y=y
    @name=name
  end

  def pair
    return x,y
  end

  RIGHT = Direction.new(1,0, "right")
  LEFT = Direction.new(-1,0, "left")
  UP = Direction.new(0,-1, "up")
  DOWN = Direction.new(0,1, "down")

end


class Bally
  attr_accessor :images,:tiles,:height,:width,:steps,:pb,:drawingarea,:gc,:gridwidth,:gridheight,:grid,:start,:finish

  def initialize()
    @width=800
    @height=600
    @gridwidth=10
    @gridheight=10
    @expired_balls=[]

    @grid=[]
    @gridwidth.times { @grid << Array.new(gridheight) }
    @start=[0,5]
    @finish=[6,9]
    @grid[3][5]=Direction::UP
    @grid[3][2]=Direction::LEFT
    @grid[6][2]=Direction::UP

    @images={}
    @steps=25
    puts "Preloading images"
    (0..@steps).each { |i|
      name="xspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
      name="yspin%02d"%i
      images[name] = Gdk::Pixbuf.new("images/#{name}.png")
    }
    ["up","down","left","right","start","finish"].each { |name|
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
    puts levelsize
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
    @drawingarea.window.draw_rectangle(@drawingarea.style.bg_gc(@drawingarea.state), true, 0, 0, width, height)

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
      return [height * gridwidth / gridheight, height].map { |i| i*0.8 }
    else
      return [width, width * gridheight / gridwidth].map { |i| i*0.8 }
    end
  end

  def start
    @balls=[]

    area=drawingarea
    area.add_events(Gdk::Event::BUTTON_PRESS_MASK)
    area.signal_connect("button-press-event") { |e,d|
      row = ((d.y - y_offset)*gridwidth/levelsize[0]).to_int
      column = ((d.x - x_offset)*gridheight/levelsize[1]).to_int
      puts row,column,grid[row][column]
      if @start==[column, row]
        #clicked on start
        @balls << Ball.new(@start[0],@start[1],self)
      elsif grid[column][row]
        #clicked on an arrow tile
        order =[ Direction::RIGHT, Direction::DOWN, Direction::LEFT, Direction::UP ]
        puts @grid[column][row]
        @grid[column][row] = order[(order.index(@grid[column][row]) + 1) % 4]
        puts @grid[column][row]
      end
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
    draw_start_finish()
    draw_arrows()
    draw_balls()
  end

  def draw_start_finish()
    center_image gridcenter(@start[0], @start[1]), "start"
    center_image gridcenter(@finish[0], @finish[1]), "finish"
  end

  def center_image(center, image_name)
    pb=images[image_name]
    drawingarea.window.draw_pixbuf(gc, pb, 0, 0, center[0]-pb.width/2, center[1]-pb.height/2, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
  end

  def draw_balls()
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
          pb = images[dir.name]
          gx = center[0] - pb.width/2
          gy = center[1] - pb.height/2
          drawingarea.window.draw_pixbuf(gc, pb, 0, 0, gx, gy, -1, -1, Gdk::RGB::DITHER_NONE, -1, -1)
        end
      }
    }
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
    @direction=Direction::RIGHT
    @step=0
    @kleur=0

    puts "x = #{x}"
    puts "y = #{y}"
  end
  
  def draw(ctx)
    gridcenter1=ctx.gridcenter(@x, @y)
    gridcenter2=ctx.gridcenter(@x + @direction.x, @y + @direction.y)
    @direction == Direction::RIGHT and imgname="yspin%02d"%(ctx.steps-@step)
    @direction == Direction::LEFT and imgname="yspin%02d"%(@step)
    @direction == Direction::UP and imgname="xspin%02d"%(ctx.steps-@step)
    @direction == Direction::DOWN and imgname="xspin%02d"%(@step)
    gx = gridcenter1[0] + (gridcenter2[0]-gridcenter1[0]) * @step/ctx.steps
    gy = gridcenter1[1] + (gridcenter2[1]-gridcenter1[1]) * @step/ctx.steps
    ctx.center_image([gx,gy], imgname)
  end

  def update(ctx)
    @step+=1
    if @step>=ctx.steps
      @step=0
      @x+=@direction.x
      @y+=@direction.y
      puts "new ball position is #{@x},#{@y}"

      if [x,y] == ctx.finish
        puts "TODO: play a 'thank you' sound"
        ctx.ball_expired(self)
      elsif @x < 0 || @x >= ctx.gridwidth || @y < 0 || @y >= ctx.gridheight
        ctx.ball_expired(self)
      elsif ctx.grid[x][y]
        @direction=ctx.grid[x][y]
      end
    end
  end

end


bally=Bally.new
bally.start()

