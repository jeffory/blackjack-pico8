pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
mouse = {
  init = function(self)
    poke(0x5f2d, 1)
    self:poll()
  end,
  poll = function(self)
    -- mouse x and y coords
    self.x = stat(32)-1
    self.y = stat(33)-1
    -- button pressed
    -- 1 = primary
    -- 2 = secondary
    -- 3 = middle
    self.b = stat(34)
    -- mouseup?
    self.mu = self.pmb and stat(34)==0
    -- primary button?
    self.pmb = stat(34)==1
  end,
  draw = function(self)
    self:poll()
    spr(1,self.x,self.y)
  end
}

background = {
  draw = function()
    cls(1)
    -- pattern:
    -- 1000
    -- 0100
    -- 0010
    -- 0001
    fillp(0b1000010000100001.1)
    rectfill(0,0,128,128,2)
    fillp()
  end
}

game = {
  player_card = {},
  player_total = 0,
  player_won = false,

  computer_card = {},
  computer_total = 0,
  computer_won = false,

  ended = false,

  new = function(self)
    self.player_card = {}
    self.player_total = 0
    self.player_won = false
    self.computer_card = {}
    self.computer_total = 0
    self.computer_won = false
    self.ended = false
  end,

  deal_card = function(self, player_deal)
    if player_deal then
      add(self.player_card,card:rnd())
      
      if self:computer_wants_card() then
        add(self.computer_card,card:rnd())
      end

      self:calc_totals()
    else
      -- player's finished, finish
      while self:computer_wants_card() do
        add(self.computer_card,card:rnd())
        self:calc_totals()
      end
    end

    self:check_score()
  end,

  -- top tier ai
  computer_wants_card = function(self)
    return self.computer_total < 17
  end,

  calc_totals = function(self)
    self.computer_total = self:calc_total(self.computer_card)
    self.player_total = self:calc_total(self.player_card)
  end,

  calc_total = function(self,values)
    -- how many aces to calc
    -- at the end of the loop
    local aces = 0
    local total = 0
    
    -- eg: c=h6
    for c in all(values) do
      -- eg: c=6
      v = sub(c,2)
      
      if (v=="a") then
        aces+=1
      elseif (v=="k" or v=="q" or v=="j") then
        total+=10
      else
        total+=tonum(v)
      end
    end
      
    -- calculate the aces
    for x = 1,aces do
      -- if there's one ace and
      -- 21 - total > 11
      if 21-total >= 11 then
        total+=11
      else
        total+=1
      end
    end

    return total
  end,

  check_score = function(self, force_end)
    -- check if someone won
    if game.player_total == game.computer_total then
      -- draw or both went over 21
    elseif game.player_total == 21 or game.computer_total > 21 then
      self.ended = true
      player_won = true
      end_game_text = "player won!!"
    elseif game.computer_total == 21 or game.player_total > 21 then
      end_game = true
      player_won = false
      end_game_text = "cpu won :("
    end

    -- player and cpu are staying, see who's closer
    if force_end then
      self.ended = true
    end
  end,
}

function rrect(x,y,x2,y2,fill,border)
  rectfill(x+1,y+1,x2-1,y2-1,fill)
  -- "rounded" rect border
  line(x+1,y,x2-2,y,border)
  line(x2-1,y+1,x2-1,y2-1,border)
  line(x2-2,y2,x+1,y2,border)
  line(x,y2-1,x,y+1,border)
end

ui = {
  splash_screen = true,
  win_screen = false,
  t = 1,
  tick = 3,

  draw = function(self)
    if self.splash_screen then
      for i=1,self.t do
        print("blackjack",rnd(128),rnd(128),1)
        if self.t < 30 then
          self.t+=1
        end
      end

      print("blackjack",45,8,7)

      self:_button(
        "new game",30,50,100,65,
        function ()
          self.splash_screen = false
        end
      )
    elseif self.win_screen then

    else
      -- game screen
      self:draw_game()
    end
  end,

  draw_game = function(self)
    rectfill(6,6,44,14,2)
    print("blackjack",8,8,7)
    
    card:drawdeck(game.computer_card,"cpu"..' ('..game.computer_total..'):',8,20)
    card:drawdeck(game.player_card,"player"..' ('..game.player_total..'):',8,60)

    if game.ended then
      return
    end

    self:_button(
      "hit",8,100,50,115,
      function ()
        game:deal_card(true)
      end
    )
    
    self:_button(
      "stay",60,100,100,115,
      function ()
        game:deal_card(false)
      end
    )
  end,
    
  _button = function(self,text,x,y,x2,y2,call)
    local mouseover = mouse.x > x and mouse.x < x2 and mouse.y > y and mouse.y < y2

    if mouseover then
      rrect(x,y,x2,y2,6,12)
    else
      rrect(x,y,x2,y2,6,1)
    end
    
    print(text, (x+(x2-x)/2)-(#text*2),y+((y2-y)/2)-1)
    
    if mouseover and mouse.mu and call then
      call()
    end
  end,
}

card = {
  suits = {'h','d','s','c'},
  values = {1,2,3,4,5,6,7,8,9,10,"j","q","k","a"},

  rnd = function(self)
    return rnd(self.suits)..rnd(self.values)
  end,
  
  _drawcard = function(self,value,x,y)
    rrect(x,y,x+19,y+24,7,13)
    print(sub(value,2),x+2,y+2)
  
    -- @todo: card graphics
    --print(sub(value,1,1),x+8,y+10)
    
  end,

  drawdeck = function(self,card,title,x,y)
    print(title,x,y,7)

    for c in all(card) do
      self:_drawcard(c,x,y+8)
      x+=20
    end
  end,
}

function _init()
  mouse:init()
  
  -- start
  game:deal_card(true)
end

function _draw()
  -- background draw clears screen
  background:draw()
  ui:draw()
  mouse:draw()

  -- if end_game==true then
  --   rectfill(8,54,118,64,0)
  --   print(end_game_text,44,57,7)
  --   print('p: '.. card.player_total..' vs c:'..card.computer_total)
  -- end
end

__gfx__
77770000dd0000003b3b3b3b0ee0ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000d7d00000b3b3b3b3eeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000d77d00003b3b3b3beeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070000d777d000b3b3b3b30eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d7777d003b3b3b3b00eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777d000b3b3b3b3000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddd00003b3b3b3b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000b3b3b3b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
