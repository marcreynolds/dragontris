# TODO: remove this later
$gtk.reset

def tick(args)
  args.state.game ||= TetrisGame.new(args)
  args.state.game.tick
end

class TetrisGame
  def initialize(args)
    @args = args
    @next_move = 30
    @next_piece = nil
    @score = 0
    @gameover = false
    @grid_w = 10
    @grid_h = 20
    @current_piece_x = 5
    @current_piece_y = 0
    @game_speed = 1.0

    @grid = []
    for x in 0..@grid_w-1 do
      @grid[x] = []
      for y in 0..@grid_h-1 do
        @grid[x][y] = 0
      end
    end

    @color_index = [
      [ 0, 0, 0 ],
      [ 255, 0, 0 ],
      [ 0, 255, 0],
      [ 0, 0, 255 ],
      [ 255, 255, 0 ],
      [ 255, 0, 255 ],
      [ 0, 255, 255 ],
      [ 127, 127, 127 ]
    ]

    select_next_piece
    select_next_piece
  end

  def tick
    iterate
    render
  end

  def current_piece_colliding?
    for x in 0..current_piece.length-1 do
      for y in 0..current_piece[x].length-1 do
        next if current_piece[x][y] == 0

        return true if current_piece_y + y >= grid_h-1
        return true if grid[current_piece_x + x][current_piece_y + y + 1] != 0
      end
    end
    false
  end

  def select_next_piece
    @current_piece = @next_piece
    @current_piece_y = 0
    @current_piece_x = 5
    x = rand(6) + 1
    @next_piece = case x
                     when 1
                       [ [x, x], [0, x], [0, x] ]
                     when 2
                       [ [x,x,x,x] ]
                     when 3
                       [ [x,0], [x,x], [0,x] ]
                     when 4
                       [ [0,x], [x,x], [x,0] ]
                     when 5
                       [ [x,x], [x,x] ]
                     when 6
                       [ [0,x], [x,x], [0,x] ]
                     when 7
                       [ [0, x], [0, x], [x, x] ]
                     end
  end

  def plant_current_piece
    (0..current_piece.length-1).each do |x|
      (0..current_piece[x].length-1).each do |y|
        if current_piece[x][y] != 0
          grid[current_piece_x + x][current_piece_y + y] = current_piece[x][y]
        end
      end
    end

    # see if any rows neew to be cleared out
    for y in 0..grid_h-1
      full = true
      for x in 0..grid_w-1
        if grid[x][y] == 0
          full = false
          break
        end
      end
      if full
        @score += 1
        for i in y.downto(1) do
          for j in 0..grid_w-1
            grid[j][i] = grid[j][i-1]
          end
        end
        for i in 0..grid_w-1
          grid[i][0] = 0
        end
      end
    end

    select_next_piece
    if current_piece_colliding?
      @gameover = true
    end
  end

  def rotate_current_piece_left
    @current_piece = @current_piece.transpose.map(&:reverse)
    if (current_piece_x + current_piece.length) >= grid_w
      @current_piece_x = grid_w - current_piece.length
    end
  end

  def rotate_current_piece_right
    @current_piece = @current_piece.transpose.map(&:reverse)
    @current_piece = @current_piece.transpose.map(&:reverse)
    @current_piece = @current_piece.transpose.map(&:reverse)
  end

  def current_piece_colliding

  end

  def iterate
    k = args.inputs.keyboard
    c = args.inputs.controller_one

    if @gameover
      if k.key_down.space || c.key_down.start
        $gtk.reset
      end
      return
    end

    if (k.key_down.left || c.key_down.left) && current_piece_x > 0 && grid[current_piece_x-1][current_piece_y] == 0
      @current_piece_x -= 1
    end
    if (k.key_down.right || c.key_down.right) && (current_piece_x + current_piece.length) < grid_w
      @current_piece_x += 1
    end

    if k.key_down.down || k.key_held.down || c.key_down.down || c.key_held.down
      @next_move -= 10 * @game_speed
    end

    if k.key_down.a
      rotate_current_piece_left
    end

    if k.key_down.s
      rotate_current_piece_right
    end

    @next_move -= 1 * @game_speed
    if @next_move <= 0 # drop the piece
      if current_piece_colliding?
        plant_current_piece
      else
        @current_piece_y += 1
      end
      @next_move = 30
    end
  end

  def render
    render_background
    render_grid
    render_current_piece
    render_next_piece
    render_score
  end

  def render_score
    args.outputs.labels << [75, 75, "Score: #{@score}", 15, 10, 255, 255, 255, 255]
    if @gameover
      args.outputs.labels << [ 200, 450, "GAME OVER", 100, 255, 255, 255, 255]
    end
  end

  def render_current_piece
    render_piece @current_piece, current_piece_x, current_piece_y
  end

  def render_next_piece
    render_grid_border(13, 2, 8, 8)
    center_x = (8-@next_piece.length)/2
    center_y = (8-@next_piece[0].length)/2
    render_piece(@next_piece, 13 + center_x, 2 + center_y)
    args.outputs.labels << [900, 640, "Next Piece", 10, 255, 255, 255, 255]
  end

  def render_piece(piece, piece_x, piece_y)
    (0..piece.length-1).each do |x|
      (0..piece[x].length-1).each do |y|
        render_cube(piece_x + x, piece_y + y, piece[x][y]) if piece[x][y] != 0
      end
    end
  end

  def render_grid
    (0..grid_w-1).each do |x|
      (0..grid_h - 1).each do |y|
        render_cube(x, y, grid[x][y]) if grid[x][y] != 0
      end
    end
  end

  # X and Y and positions in the tetris grid, not pixels
  def render_cube(x, y, color)
    box_size = 30
    grid_x = (1280 - (grid_w * box_size)) / 2
    grid_y = (720 - ((grid_h - 2) * box_size)) / 2
    args.outputs.solids << [ grid_x + (x * box_size), (720 - grid_y) - (y * box_size), box_size, box_size, *@color_index[color]]
    args.outputs.borders << [ grid_x + (x * box_size), (720 - grid_y) - (y * box_size), box_size, box_size, 255, 255, 255]
  end

  def render_grid_border(x, y, w, h)

    color = 7
    (x..(x+w)-1).each do |i|
      render_cube(i, y, color)
      render_cube(i, (y+h)-1, color)
    end

    (y..(y+h)-1).each do |i|
      render_cube(x, i, color)
      render_cube((x+w)-1, i, color)
    end
  end

  def render_background
    args.outputs.sprites << [75, 300, 300, 300, "console-logo.png"]
    args.outputs.solids << [0,0,1280,720,0,0]

    x = -1
    y = -1
    w = grid_w + 2
    h = grid_h + 2
    render_grid_border(x,y,w,h)
  end

  private

  attr_accessor :args, :score, :gameover, :grid_w, :grid_h, :current_piece_x, :current_piece_y, :grid, :current_piece
end
