-- API info https://atelier801.com/topic?f=5&t=451587
-- module info https://atelier801.com/topic?f=6&t=781139

-- TODO list --
-- XML parsing
    -- no bloon
    -- opportunist
    -- no B?
-- stats gui
-- help gui
-- info gui
-- finish displaying game info


-- big print, intended for debugging
function bigPrint(text)
    if text then
        print('<font color="#0000FF"><b>'..text..'</b></font>')
    else
        print('<font color="#0000FF"><b>nil</b></font>')
    end
end

-- prints message to all players
function printToAll(message)
    for name,obj in pairs(tfm.get.room.playerList) do -- name is key, and obj is value
        if tfm.get.room.playerList[name] then
            tempChatMessage(message,name)
        end
    end
end


function tempChatMessage(message,playerName)
    print('<font color="#00FF00">['..playerName..']</font>'..message)
end




-- Initialize database
database = {}
database['players'] = {}
database['mods'] = {}
database['mods']['Condensation#0000'] = 'admin'
database['mods']['Sublimation#2025'] = 'mod'
database['maps'] = {}
database['maps']['divinity'] = {
    -- diff 1
    {'@7409631','@199265','@348365','@576319','@576456','@1306423','@2589119','@7236632','@219032','@1667676','@1406626'},

    -- diff 2
    {'@245354','@357214','@249255','@367747','@426398','@460646','@437313','@474113','@868945','@1050116'},

    -- diff 3
    {'@169710','@172357','@239941','@182878','@360778','@287193','@461925','@490175','@617225','@772825'},

    -- diff 4
    {'@7671925','@7686575','@7692682','@293083','@364544','@273581','@467799','@423670','@497021','@1073256','@1124454','@1396171','@1333807'},

    -- diff 5
    {'@7686577','@7686775','@7696244','@7699394','@171093','@171097','@559622','@476169','@1125907','@1326880','@1440257','@1483437','@1499645','@2136058'},

    -- diff 6
    {'@7675800','@7685726','@7687800','@763212','@2385346','@2092138','@4372661','@6878899','@7043065','@7043488','@4386389','@7179092','@6888926','@6901527'},

    -- diff 7
    {'@7687165','@7687678','@7688839','@7692561','@7693004','@7612485','@3731755','@7619605','@3804339','@5829289','@5829289','@6894779','@6892496','@6943100','@7147593','@7059638','@6870236'},

    -- diff 8
    {'@5695427','@4372606','@7062450','@7181181','@7627759','@7713564','@7705639','@7701165','@7593320'},

    -- diff 9
    {'@7710806','@7595604','@7596494','@7602406','@7606870','@7607205','@7610094','@7610340','@7610824','@7605426'}
}
database['maps']['spiritual'] = {
    -- diff 1
    {'@129420','@243562','16','90','0','@1900072','@237106','17','36','@299158'},

    -- diff 2
    {'@2068355','@950364','@438271','@156104','@460646','@388828','@224120','@306731','@500471','@1777037'},

    -- diff 3
    {'@6966893','@969655','@237548','@234373','@5749156','@196087','@156461','@2088714','@196275','@2092021'},

    -- diff 4
    {'@233629','@209554','@307669','@771582','@188815','@7221038','@3397442','@164118','@227051','@188815'},

    -- diff 5
    {'@387184','@204088','@236693','@2359943','@923918','@2096219','@231731','@233166','@205419','@217000'},

    -- diff 6
    {'@205530','@206502','@6230807','@236796','@230969','@216341','@299382','@2923482','@512456','@252048'},

    -- diff 7
    {'@2501595','@1417248','@3296601','@7073610','@2998240','@553899','@417758','@520924','@447984','@234632','@739499','@425908','@217526','@3905014','@369747','@6709605','@214832','@2389050'},

    -- diff 8
    {'@440075','@454431','@373987','@1413649','@476210','@2388832','@779801','@6839089','@619677','@492211'},

    -- diff 9
    {'@3216511','@476207','@3545327','@615403','@465681','@469323','@3827080','@6248664','@4711589','@4977322'}
}


-- global constants
fullGameTime = 150
deathGameTime = 20

-- global variables
currentSham = nil
nextSham = nil
ratsLeft = 0
shamOnly = false
mapDifficulty = nil


-- displays all info for the new game
function displayGameInfo()
    infoStr = '\n<font color="#FF0000"><b>Map Info:</b> ' .. tfm.get.room.currentMap .. ' difficulty '..mapDifficulty..'</font>\n'
    infoStr = infoStr .. '<font color="#00FFFF"><b>Shaman Info:</b> ' .. currentSham .. '</font>\n'
    print(infoStr)
end



-- parses through all the players,
    -- determines/sets the sham
    -- determines numer of rats
function parsePlayers()
    currentSham = nil
    ratsLeft = 0

    -- get highest scoring player
    highestScore = -10
    highestScorePlayer = nil
    for name,obj in pairs(tfm.get.room.playerList) do -- name is key, and obj is value
        tfm.exec.setShaman(name,false)
        ratsLeft = ratsLeft + 1
        if obj.score > highestScore then
            highestScore = obj.score
            highestScorePlayer = name
        end
    end

    -- set the shaman for the game
    if tfm.get.room.playerList[nextSham] then
        tfm.exec.setShaman(nextSham)
        currentSham = nextSham
    else
        tfm.exec.setShaman(highestScorePlayer)
        currentSham = highestScorePlayer
    end
    nextSham = nil

end





-- adjusts time or makes a new game as needed whenever a rat leaves/wins/dies
function playerGoneAdjustment(playerName)
    ratsLeft = ratsLeft-1

    -- end the game when everyone is gone
    if ratsLeft <= 0 then
        tfm.exec.setGameTime(1) -- just in case end of game doesn't run correctly
        endOfGame()

    -- when all players but the sham are gone set time to deathtime
    elseif (ratsLeft == 1) and (not shamOnly) then
        tfm.exec.setGameTime(deathGameTime)

    -- when the sham is gone, change game time
    elseif playerName == currentSham then
        tfm.exec.setGameTime(deathGameTime)
    end

end



-- adds/initializes a player to the db if needed
function addPlayerToLocalDatabase(playerName)
    if not database['players'][playerName] and playerName then
        database['players'][playerName] = {}

        database['players'][playerName]['mode'] = 'spiritual'

        database['players'][playerName]['difficulty'] = {}
        database['players'][playerName]['difficulty']['spiritual'] = {1,1}
        database['players'][playerName]['difficulty']['divinity'] = {1,1}

        database['players'][playerName]['level'] = {}
        database['players'][playerName]['level']['divinity'] = 1
        database['players'][playerName]['level']['spiritual'] = 1

        database['players'][playerName]['exp'] = {}
        database['players'][playerName]['exp']['divinity'] = 0
        database['players'][playerName]['exp']['spiritual'] = 0

        bigPrint(playerName.. ' was added to the DB')
    end
end





-- starts up a new game
function startNextGame()

    -- determine next sham
    highestScore = -10
    for name,obj in pairs(tfm.get.room.playerList) do -- name is key, and obj is value
        if obj.score > highestScore and name ~= currentSham then
            highestScore = obj.score
            nextSham = name
        end
    end
    if not nextSham then
        nextSham = currentSham
    end

    -- add them the the db
    addPlayerToLocalDatabase(nextSham)

    -- select a new map
    mapMode = database['players'][nextSham]['mode']
    diffTable = database['players'][nextSham]['difficulty'][mapMode]
    mapDifficulty = math.random(diffTable[2]-diffTable[1]+1)-1+diffTable[1]
    nextMapList = database['maps'][mapMode][mapDifficulty]
    nextMap = tfm.get.room.currentMap
    while nextMap == tfm.get.room.currentMap do
        nextMap = nextMapList[math.random(#nextMapList)]
    end
    flippedBool = math.random(2) == 1

    -- store some info about the next game


    -- start next game
    tfm.exec.newGame( nextMap,flippedBool)

end







--function that runs at the end of a game
function endOfGame()
    tfm.exec.setPlayerScore(currentSham,0) -- reset shams score
    startNextGame()
end


-- everything that happens when a new game happens
function eventNewGame()
    print('<font color="#FFFFFF"><b>===NEW GAME===</b></font>')





    -- set up the sham and count players
    parsePlayers()
    shamOnly = ratsLeft == 1

    -- set up shaman
    addPlayerToLocalDatabase(currentSham)
    if database['players'][currentSham]['mode'] == 'spiritual' then
        tfm.exec.setShamanMode(currentSham,0)
    elseif database['players'][currentSham]['mode'] == 'divinity' then
        tfm.exec.setShamanMode(currentSham,2)
    end
    tfm.exec.disableAllShamanSkills(true)

    -- set the game time
    tfm.exec.setGameTime(fullGameTime)

    -- display info to all players about the game
    displayGameInfo()

end


-- this function runs when playerName dies
function eventPlayerDied(playerName)
    -- death means you get +1... unless ur sham
    if playerName ~= currentSham then
        tfm.exec.setPlayerScore(playerName,1+tfm.get.room.playerList[playerName].score)
    end

    -- adjust time for when a player is gone
    playerGoneAdjustment(playerName)
end



-- this function runs when playerName getsin the hole
function eventPlayerWon(playerName)

    -- people only get +10 per win, sham gets none
    if playerName ~= currentSham then
        tfm.exec.setPlayerScore(playerName,10+tfm.get.room.playerList[playerName].score)
    end

    -- adjust time for when a player is gone
    playerGoneAdjustment(playerName)
end



-- i don't think i need this
-- function eventPlayerLeft(playerName)
--     -- adjust time for when a player is gone
--     playerGoneAdjustment(playerName)
-- end



-- this function is called every 500ms
function eventLoop(elapsedTime, remainingTime)
    -- end the game when time runs out
    if remainingTime <= 0 then
        endOfGame()
    end
end


function printTable(table)
    for k,v in pairs(table) do
        bigPrint('table['..k..'] = '..v)
    end
end




-- this function is called whenever a player uses !commands
function eventChatCommand(playerName,command)

    -- make sure player is in db before changing their db settings
    addPlayerToLocalDatabase(playerName)

    -- parse the arguments in the command
    args = {}
    for substring in command:gmatch("%S+") do
       table.insert(args, substring)
    end


    -- !m is death
    if command == 'mort' or command == 'm' then
        tfm.exec.killPlayer(playerName)


    --set players mode if requested
    elseif args[1] == 'setmode' then
        if args[2] == 'sp' or args[2] == 'spiritual' then
            database['players'][playerName]['mode'] = 'spiritual'
            tempChatMessage('mode set to spiritual',playerName)
        elseif args[2] == 'div' or args[2] == 'divinity' then
            database['players'][playerName]['mode'] = 'divinity'
            tempChatMessage('mode set to divinity',playerName)
        else
            tempChatMessage('invalid mode',playerName)
        end


    --set players diff if requested
    elseif args[1] == 'setdiff' then
        setDiff(args,playerName)


    -- skips the current map, only sham and mods can do this
    elseif args[1] == 'skip' then
        if playerName == currentSham or database['mods'][playerName] then
            endOfGame()
        end

    -- only mods can murder players
    elseif  args[1] == 'kill' then
        if database['mods'][playerName] and tfm.get.room.playerList[args[2]] then
            tfm.exec.killPlayer(args[2])
        end



    -- anything besides the approved commands is invalid
    else
        tempChatMessage('Invalid command. You should feel bad.',playerName)
    end

end


-- dedicated function for setdiff comand
function setDiff(args,playerName)

    start = nil
    stop = nil

    -- if there are 2 numbers are seperated by a space
    if #args == 3 then
        start = tonumber(args[2])
        stop  = tonumber(args[3])

    elseif #args == 2 then
        --
        -- args = {}
        -- args[2] = '4-5'

        -- check for a dash
        dashLoc = string.find(args[2],'-')

        -- if they enter a dash, interpret the single number
        if dashLoc then

            diffStr = string.gsub(args[2],"-"," ")
            diffs = {}
            for substring in diffStr:gmatch("%S+") do
               table.insert(diffs, substring)
            end

            if #diffs == 2 then
                start = tonumber(diffs[1])
                stop  = tonumber(diffs[2])
            end

        -- if they enter no dash, interpret the single number
        else
            start = tonumber(args[2])
            stop  = tonumber(args[2])
        end

    end

    -- check for valid difficulty
    if start and stop and stop>=start and start>0 and stop>0 and start<10 and stop<10 then
        mode = database['players'][playerName]['mode']
        database['players'][playerName]['difficulty'][mode] = {start,stop}
        if start ~=stop then
            tempChatMessage('difficulty in '..mode..' set to '..start..'-'..stop,playerName)
        else
            tempChatMessage('difficulty in '..mode..' set to '..start,playerName)
        end

    -- the player entered an invalid difficulty
    else
        tempChatMessage('invalid difficulty',playerName)
    end
end







-- stop tfm's auto BS
-- tfm.exec.disableAfkDeath(true)
tfm.exec.disableAutoScore(true)
tfm.exec.disableAutoTimeLeft(true)
tfm.exec.disableAllShamanSkills(true)
tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoShaman(true)

-- start the first game
startNextGame()
