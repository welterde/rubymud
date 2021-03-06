class Command
	include Term::ANSIColor
	attr_accessor(:c, :s, :client, :online, :fighting)
	attr_reader(:fight_commands)
	
	#actions get enq'd to client.action_queue

	def initialize(character, session, client)
		@c = character
		@s = session
		@client = client
		@online = true
		@fighting = false
		@fight_commands = %w{ say s look l attack kill k att status sta stat help get pickup drop destroy junk wield wie inventory inv equipment eq unwield unwie wear wea remove rem unwear unwea }
	end
	
	def say(message)
		args = []
		args[0] = @c
		args[1] = message.join(" ")
		@client.changed
		@client.notify_observers(:say, args)
	end
	
	alias s say
	
	def look(args)
		if args.length > 0
			if @c.area.characters.has_key?(args[0])
				@s.puts @c.area.characters[args[0]].description
			elsif @c.area.has_npc?(args[0])
				@s.puts @c.area.npc(args[0]).description
			elsif @c.area.has_item?(args[0])
				@s.puts @c.area.item(args[0]).description
			elsif @c.has_item?(args[0])
				@s.puts @c.item_by_name(args[0]).description
			elsif @c.area.exits.has_key?(args[0])
				@s.puts @c.area.exits[args[0]] # this should be an exit description
			else
				@s.puts "I don't see him/her/zir/it/them here."
			end
		else
			@s.puts @c.area.view(@c)
		end
	end
	
	alias l look
	
	def n(args)
		go("north")
	end
	
	alias north n
	
	def s(args)
		go("south")
	end
	
	alias south s
	
	def e(args)
		go(["east"])
	end
	
	alias east e
	
	def w(args)
		go(["west"])
	end
	
	alias west w
	
	def u(args)
		go(["up"])
	end
	
	alias up u
	
	def d(args)
		go(["down"])
	end
	
	alias down d
	
	def go(exit)
		if @c.area.exits.has_key?(exit[0])
			args = []
			args[0] = @c
			args[1] = @c.region.areas[@c.area.exits[exit[0]]]
			@client.changed
			@client.notify_observers(:go, args)
		else
			@s.puts "I don't recognize that place."
		end
	end
	
	def get(item)
	  if item[0] == "all"
	    @c.area.items.each_value do |i|
	      if @c.pickup(i)
  	      @client.changed
	        @client.notify_observers(:picked, [@c, i])
	        @s.puts "You feel a strange attachment to this #{i.name}." if i.cursed?
        else
          @s.puts "You're not strong enough to pick up a #{i.name}."
        end
	    end
		elsif @c.area.has_item?(item[0])
			target = @c.area.item(item[0])
			if @c.pickup(target)
				@client.changed
				@client.notify_observers(:picked, [@c, target])
				@s.puts "You feel a strange attachment to this #{target.name}." if target.cursed?
			else
				@s.puts "You're not strong enough to pick that up."
			end
		else
			@s.puts "You don't see that here."
		end
	end
	
	alias pickup get
	
	def drop(i)
	  if i[0] == "all"
	    @c.items.each_with_index do |item, index|
	      if @c.drop(index)
	        @client.changed
	        @client.notify_observers(:dropped, [@c, item])
	      else
	        @s.puts "You can't discard your #{item.name}.  It's either cursed or a video game controller (or both)."
	      end
      end
    else
	    i = i[0].to_i
		  if @c.item(i)
			  target = @c.item(i)
			  if @c.drop(i)
				  @client.changed
				  @client.notify_observers(:dropped, [@c, target])
			  else
				  @s.puts "You can't discard your #{target.name}.  It's either cursed or a video game controller (or both)."
			  end
		  else
			  @s.puts "You don't appear to have that."
		  end
		end
	end
	
	def destroy(i)
	  i = i[0].to_i
		if @c.item(i)
			target = @c.item(i)
			if @c.destroy(i)
				@client.changed
				@client.notify_observers(:destroyed, [@c, target])
			else
				@s.puts "You can't destroy this item.  Perhaps it's cursed, indestructible or you're just running in to a general violation of the second law of thermodynamics."
			end
		else
			@s.puts "You don't appear to have that."
		end
	end
	
	alias junk destroy
	
	def wield(i)
	  i = i[0].to_i
		if target = @c.item(i)
			#target = @c.item(i)
			if @c.wield(i)
				@client.changed
				@client.notify_observers(:wield, [@c, target])
			else
				@s.puts "You fail to wield your #{target.name}.  Perhaps you are not strong enough in some way?  Perhaps you are already wielding something?"
			end
		else
			@s.puts "You don't appear to have that."
		end
	end
	
	alias wie wield
	
	def unwield(item) # Since you can only wield one item, could change this to not require or use any args
		if @c.wield_item?(item[0])
			target = @c.equipment[:wield]
			if @c.unwield(target)
				@client.changed
				@client.notify_observers(:unwield, [@c, target])
			else
				@s.puts "You can't unwield your #{target.name}.  That's not always a good sign."
			end
		else
			@s.puts "You don't appear to be wielding that."
		end
	end
	
	alias unwie unwield
	
	def wear(i)
	  i = i[0].to_i
	  if @c.item(i)
	    target = @c.item(i)
	    if @c.wear(i)
	      @client.changed
	      @client.notify_observers(:wear, [@c, target])
	    else
	      @s.puts "You fail to wear your #{target.name}.  Perhaps you are not strong enough in some way?  Perhaps you're already wearing something there?"
	    end
	  else
	    @s.puts "You don't appear to have that."
	  end
	end
	
	alias wea wear
	
	def remove(type)
	  target = @c.equipment[type[0].to_sym]
	  if @c.remove(type[0].to_sym)
	    @client.changed
	    @client.notify_observers(:remove, [@c, target])
	    @s.puts "You remove your #{target.name}."
	  else
	    @s.puts "You're not wearing anything there."
	  end
	end
	
	alias rem remove
	alias unwear remove
	alias unwea remove
	
	def inventory(args)
		@s.puts "\nInventory\n---------\n"
		@c.items.each_with_index do |item, index|
			@s.puts "[#{index}]\t#{item.inventory_name}"
		end
		@s.puts "\n"
	end
	
	alias inv inventory
	
	def equipment(args)
		@s.puts "\nEquipment\n---------\n"
		@c.equipment.each do |key,val|
			@s.puts "[#{key.to_s}]\t\t#{val.inventory_name}"
		end
		@s.puts "\n"
	end
	
	alias eq equipment
	
	def attack(mobile) #can't attack players yet
		target = @c.area.npc(mobile[0])
		if @client.target == target
			@s.puts "You try your best..."
		else
			@s.puts "You eye the #{target.name} menacingly."
			Thread.new {
				f = Fight.new(@client.world)
				f.start(@client, target)
			}
		end
	end
	
	alias kill attack
	alias k attack
	alias att attack
	
	def status(args)
		@s.puts "You're feeling #{@c.health} right now."
		@s.puts "Your current burden is #{@c.burden}."
	end
	
	alias sta status
	alias stat status
	
	def help(args)
		@s.puts "No voices magically call from the sky to help you.  You do, however, get the nagging suspicion that some things may be case-sensitive.  If only you had parents.  Maybe you can get assistance from another player?"
	end
	
	def quit(args)
		unless @s.closed? or args == "disconnected"
		  @s.puts "Saving..."
		  @s.puts "Goodbye."
  	end
		@online = false
	end
end
