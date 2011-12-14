require 'sdl'

SDL.init SDL::INIT_VIDEO
Screen = SDL::set_video_mode 800, 600, 24, SDL::SWSURFACE
BGCOLOR = Screen.format.mapRGB 255, 255, 255
LINECOLOR = Screen.format.mapRGB 0, 0, 0

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
  attr_accessor :images,:tiles,:height,:width,:steps,:pb,:gc,:gridwidth,:gridheight,:grid,:start,:finish

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
      images[name] = SDL::Surface.load "images/#{name}.png"
      name="yspin%02d"%i
      images[name] = SDL::Surface.load "images/#{name}.png"
    }
    ["up","down","left","right","start","finish"].each { |name|
      images[name] = SDL::Surface.load "images/#{name}.png"
    }

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
    w,h = levelsize
    # Draw vertical lines
    (0..@gridwidth).each { |i|
      Screen.draw_line x_offset + i*w/gridwidth, y_offset, x_offset + i*w/gridwidth, y_offset+h, LINECOLOR
    }
    # Draw horizontal lines
    (0..@gridheight).each { |i|
      Screen.draw_line x_offset, y_offset + i*h/gridheight, x_offset + w, y_offset+ + i*h/gridheight, LINECOLOR
    }
  end

  # returns a multiple of the grid's size
  # which fits snugly in the available screen size
  def levelsize
    if (gridwidth * width > gridheight * height)
      return [height * gridwidth / gridheight, height].map { |i| i*0.8 }
    else
      return [width, width * gridheight / gridwidth].map { |i| i*0.8 }
    end
  end

  def start
    @balls=[]

    running = true
    while running
      while event = SDL::Event2.poll
         case event
           when SDL::Event2::Quit
             running = false
           when SDL::Event2::MouseButtonDown
             handle_buttondown event
         end

      end
      update_positions()
      update_graphics()
      Screen.flip
    end

  end

  def handle_buttondown(event)
    row = ((event.y - y_offset)*gridwidth/levelsize[0]).to_int
    column = ((event.x - x_offset)*gridheight/levelsize[1]).to_int
    if @start==[column, row]
      #clicked on start
      @balls << Ball.new(@start[0],@start[1],self)
    elsif grid[column][row]
      #clicked on an arrow tile
      order =[ Direction::RIGHT, Direction::DOWN, Direction::LEFT, Direction::UP ]
      @grid[column][row] = order[(order.index(@grid[column][row]) + 1) % 4]
    end
  end  

  def update_positions
    @balls.each { |ball| ball.update self }
    @balls -= @expired_balls
    @expired_balls.clear
  end

  def update_graphics
    Screen.fill_rect 0, 0, width, height, BGCOLOR

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
    #Screen.draw_rect center[0]-10, center[1]-10, 20, 20, LINECOLOR
    surf=images[image_name]
    Screen.put(surf, center[0]-surf.w/2, center[1]-surf.h/2)
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
          center_image center, dir.name
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
    ctx.center_image [gx,gy], imgname
  end

  def update(ctx)
    @step+=1
    if @step>=ctx.steps
      @step=0
      @x+=@direction.x
      @y+=@direction.y

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

