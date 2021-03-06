--- Blueprint parsing
--@module Blueprint

Blueprint = {}

---Group entities in the blueprint
--@param e entities
--@return Untyped Type of the blueprint
--@return Untyped No of rails
--@return Untyped poles in the blueprint
--@return Untyped boundingbox
--@return Untyped other entities
Blueprint.group_entities = function(e)
  local offsets = {
    pole=false, chain=false, poleEntities={}, railEntities={},
    rails={}, signals={}, concrete={}, lanes={}}
  local bpType = false
  local rails = 0
  local poles = {}
  local box = {tl={x=0,y=0}, br={x=0,y=0}}
  for i=1,#e do
    local position = diagonal_to_real_pos(e[i])
    if box.tl.x > position.x then box.tl.x = position.x end
    if box.tl.y > position.y then box.tl.y = position.y end

    if box.br.x < position.x then box.br.x = position.x end
    if box.br.y < position.y then box.br.y = position.y end

    local dir = e[i].direction or 0
    local name = e[i].name
    
    if name == "rail-chain-signal" and not offsets.chain then
      offsets.chain = {direction = dir, name = e[i].name, position = e[i].position}
      -- collect all poles in bp
    elseif global.electric_poles[e[i].name] then
      table.insert(poles, {name = name, direction = dir, position = e[i].position})
    elseif name == "straight-rail" or name == "bi-straight-rail-wood" then
      rails = rails + 1
      if not bpType then
          bpType = (dir == 0 or dir == 4) and "straight" or "diagonal"
      end
      if  (bpType == "diagonal" and (dir == 3 or dir == 7)) or
        (bpType == "straight" and (dir == 0 or dir == 4)) then
        table.insert(offsets.rails, {name = name, direction = dir, position = e[i].position, type = game.entity_prototypes[name].type})
      else
        return false, {"msg-bp-rail-direction"}
      end
    elseif name == "rail-signal" then
      table.insert(offsets.signals, {name = name, direction = dir, position = e[i].position})
    else
      local e_type = game.entity_prototypes[name].type
      local rail_entities = {["wall"]=true}
      if not rail_entities[e_type] then
        table.insert(offsets.poleEntities, {name = name, direction = dir, position = e[i].position, pickup_position = e[i].pickup_position, drop_position = e[i].drop_position, request_filters = e[i].request_filters, recipe = e[i].recipe})
      else
        table.insert(offsets.railEntities, {name = name, direction = dir, position = e[i].position})
      end
    end
  end
  return bpType, rails, poles, box, offsets
end

Blueprint.get_max_pole = function(poles, offsets)
  local max = 0
  local max_index
  for i,p in pairs(poles) do
    if global.electric_poles[p.name] > max then
      max = global.electric_poles[p.name]
      max_index = i
    end
  end
  offsets.pole = poles[max_index]
  for i,p in pairs(poles) do
    if i ~= max_index then
      table.insert(offsets.poleEntities, p)
    end
  end
end
