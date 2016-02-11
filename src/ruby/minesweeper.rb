require 'gosu'

Grid = Struct.new(:clicked, :flaged, :state) do
	def clicked?
		clicked
	end
	def flaged?
		flaged
	end
	def bomb?
		state == -1
	end
end

class MineSweeper < Gosu::Window
	def initialize
		super W*R, H*R+R
		self.caption = 'Mine Sweeper'
		_init
	end

	def update
		case @game_state
		when :over, :done
			_init if button_down?(Gosu::KbSpace)
		when :start
			if _win?
				@game_state = :done
				@ts = '%.3f' % (_time - @start_time)
				return
			end
			x = (mouse_x / R).to_i
			y = (mouse_y / R).to_i
			return if x < 0 || x >= W || y < 0 || y >= H
			if button_down?(Gosu::MsLeft)
				return if @grid[x][y].flaged?
				_random_walk(x, y) unless @grid[x][y].clicked?
				@grid[x][y].clicked = true
				@game_state = :over if @grid[x][y].bomb?
			elsif button_down?(Gosu::MsRight)
				_delay
				if @grid[x][y].flaged?
					@grid[x][y].flaged = false
					@bomb_left += 1
				else
					@grid[x][y].flaged = true
					@bomb_left -= 1
				end
			end
		end
	end

	def draw
		case @game_state
		when :over
			@font.draw("BOMB!!! PRESS SPACE TO RESTART", 0, H*R, 1, 1, 1, Gosu::Color::RED)
		when :done
			@font.draw("YOU WIN! time is #{@ts}", 0, H*R, 1, 1, 1, Gosu::Color::AQUA)
		when :start
			@font.draw("time: #{'%.3f' % (_time-@start_time)}", 0, H*R, 0)
			@font.draw("bomb: #{@bomb_left}", W*R/2, H*R, 0)
		end
		W.times do |i| H.times do |j|
			_draw_grid(i, j, @grid[i][j])
		end end
	end

	def needs_cursor?
		true
	end

	private
	def _init
		@bomb_left = Bs
		@game_state = :start
		@start_time = _time
		@font = Gosu::Font.new(15)
		@nums = [*0..9].map { |i| Gosu::Image.new("./img/grid_#{i}.png") }
		@flag = Gosu::Image.new('./img/flag.png')
		@tile = Gosu::Image.new('./img/tile.png')
		@grid = Array.new(W) { Array.new(H) { Grid.new(false, false, 0) } }
		[*0..W*H-1].shuffle[0..Bs].each { |x| @grid[x/H][x%H].state = -1 }
		W.times do |i| H.times do |j|
			next if @grid[i][j].bomb?
			bomb = 0
			Dir.each do |(dx, dy)|
				x = i + dx
				y = j + dy
				next unless 0 <= x && x < W && 0 <= y && y < H
				bomb += 1 if @grid[x][y].bomb?
			end
			@grid[i][j].state = bomb
		end end
	end

	def _time
		Gosu::milliseconds / 1000.0
	end

	def _delay(interval = 0.2)
		st = _time
		{} until _time - st > interval
	end

	def _draw_grid(x, y, grid)
		if grid.clicked?
			@nums[grid.state]
		elsif grid.flaged?
			@flag
		else
			@tile
		end.draw(x*20+0.5, y*20+0.5, 0)
	end

	def _go?
		[*0..9].shuffle.first < 3
	end

	def _win?
		if @bomb_left.zero?
			@grid.each do |row|
				row.each do |cell|
					return false if cell.flaged? && !cell.bomb?
				end
			end
		else
			@grid.each do |row|
				row.each do |cell|
					return false if !cell.clicked? && !cell.bomb?
				end
			end
		end
		true
	end

	def _random_walk(sx, sy)
		q = [[sx, sy]]
		until q.empty?
			(x, y) = q.shift
			Nei.each do |(dx, dy)|
				tx = x + dx
				ty = y + dy
				next unless 0 <= tx && tx < W && 0 <= ty && ty < H
				next if @grid[tx][ty].clicked? || @grid[tx][ty].bomb?
				@grid[tx][ty].clicked = true && q.push([tx, ty]) if _go?
			end
		end
	end

	W   = 30
	H   = 16
	R   = 20
	Bs  = W * H / 5
	Dir = [[-1, -1], [-1, 0], [-1, 1], [1, -1], [1, 0], [1, 1], [0, -1], [0, 1]]
	Nei = [[-1, 0], [1, 0], [0, -1], [0, 1]]
end

ms = MineSweeper.new
ms.show
