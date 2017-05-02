
local MainScene = class("MainScene",  cc.load("mvc").ViewBase)
local layout =require "/Users/wangqiang/ab-blast/src/app/mapscene/Layout"






function MainScene:onCreate()
    
    self:addChild(self:createMapLayer())
end

-- 创建地图
function MainScene:createMapLayer()
    local ParallaxNode  = require "/Users/wangqiang/ab-blast/src/app/mapscene/ParallaxNode"
    local winSize = cc.Director:getInstance():getWinSize()
    local scrollSize = cc.size(layout.mapWidth,5000000)

    self.scrollView = cc.ScrollView:create()
    self.scrollView:setViewSize(cc.size(winSize.width, winSize.height))
    self.scrollView:setContentSize(scrollSize)
    local contScale =1

    self.scrollView:setPosition(cc.p(0,0))
    self.scrollView:ignoreAnchorPointForPosition(true)
    self.scrollView:setDelegate()
    self.scrollView:updateInset()
    self.scrollView:setMaxScale(contScale)
    self.scrollView:setMinScale(contScale)
    self.scrollView:setClippingToBounds(true)
    self.scrollView:setBounceable(true)
    -- 创建视差图层
    self.parallaxLayer = ParallaxNode.new()
    self.parallaxLayer:setPosition(0,0)
    self.parallaxLayer:addTo(self.scrollView)

    self.scrollView:setContentSize(scrollSize)

    self.md={};
    self.spValue={};
    self.sp={}
    self:mapInit()
    self.spTap={};
    self:setMap()
    -- self:setSpine()

    -- 滑动大地图是更新大地图
    self.scrollView:registerScriptHandler(function(view)
        self.parallaxLayer:update()
        self:setMap()
        -- self:setSpine()
    end, cc.SCROLLVIEW_SCRIPT_SCROLL)

    return self.scrollView
end

-- 更新大地图 出入屏幕加载大地图和删除大地图缓存
function MainScene:setMap()
    local pos = self.scrollView:getContentOffset()
    if self.lastPositionY  == pos.y then
        return
    end

    local contentScale= self.scrollView:getZoomScale();
    local viewSize = self.scrollView:getViewSize()
    local rect = {};
    rect.y =-pos.y
    for i=1,#layout.frame do
        local info = layout.frame[i]
        rect.height =viewSize.height/info[4][2];
        -- dump(rect.y)
        -- dump(info[#info])
        if self:rectIntersectsRect(rect,info[#info],contentScale)  then
            if(self.md[i]==false or self.md[i]==nil) then
                self.md[i]=true
                local t = cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888
                if info[7] ==1 then
                    t = cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565
                elseif info[7]==0 then
                    t =cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444
                end
                cc.Texture2D:setDefaultAlphaPixelFormat(t)
                local bg=cc.Director:getInstance():getTextureCache():addImage("/Users/wangqiang/ab-blast/res_ios/gfx/map/"..info[2])
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
                local img = display.newSprite(bg)
                img:align(display.left_bottom,0,0)
                img:setTag(i)
                self.parallaxLayer:addChild(img,info[5],cc.p(info[4][1],info[4][2]),cc.p(info[3][1],info[3][2]))
            end
        else
            if self.md[i] ==true then
                local sp = self.parallaxLayer:getChildByTag(i)
                local spT = sp:getTexture();
                self.parallaxLayer:removeChild(sp,true)
                if  not newAction then
                    cc.Director:getInstance():getTextureCache():removeTexture(spT)
                end

                -- display.removeSpriteFrameByImageName(info[2] .. ".pvr")
                self.md[i]=false
            end
        end
    end
    -- self.cutSubjectPosY = pos.y
end


function MainScene:setSpine()
    local contentScale= self.scrollView:getZoomScale();
    local pos = self.scrollView:getContentOffset()
    local viewSize = self.scrollView:getViewSize()
    local rect = {};
    rect.y = -pos.y

    for i,v in ipairs(layout.animation) do
        rect.height = viewSize.height/(v.ratioY or 1)
        if self:rectIntersectsRect(rect,self.spineArr[i],contentScale) or v.notRemove then
            if(self.sp[i]==false or self.sp[i]==nil) then
                self.sp[i]=true
                -- dump(info[#info],contentScale)
                local img = mybo.SpineCache:getInstance():getSpine(v.name..".json",v.name..".atlas",v.name ..".png", v.scale or 1)
                img:setSkin(v.skin or "default")
                img:setTimeScale(v.time or 2)
                img:setRotation(v.rotation or 0)
                img:setTag(1000+i)
                if v.setName then img:setName(v.setName) end
                if v.sX~=nil then img:setScaleX(v.sX) end
                if v.sY~=nil then img:setScaleY(v.sY) end
                if type(v.run)=="table" then
                    local n = #v.run
                    img:setAnimation(0,v.run[n],false);
                    img:registerSpineEventHandler(function (event)
                        n=n-1
                        if n==0 then
                            n=#v.run
                        end
                        img:setAnimation(0,v.run[n],false);
                    end, sp.EventType.ANIMATION_COMPLETE)
                else
                    img:setAnimation(0,v.run,true);
                    if v.randomX then
                        img:registerSpineEventHandler(function (event)
                            img:setScaleX(math.random(2)==2 and 1 or -1)
                            img:setVisible(math.random(2)==2 and true or false)
                        end, sp.EventType.ANIMATION_COMPLETE)
                    else
                        img:registerSpineEventHandler(function (event)
                            img:setAnimation(0,v.run,true)
                        end, sp.EventType.ANIMATION_COMPLETE)
                    end
                end
                if v.getName then
                    local ret = self.parallaxLayer:getChildByName(v.getName)
                    if ret.findBone then
                        local value = SchedulerManager:getInstance():setFun(function (ret)
                            local x,y,rotation,scaleX,scaleY,len = ret:findBone(v.point)
                            img:setPosition(cc.p(x,y))
                            img:setRotation(rotation)
                            img:setScaleX(scaleX)
                            img:setScaleY(scaleY)
                        end,ret)
                        SchedulerManager:getInstance():starts()
                        ret:addChild(img,v.z or 1)
                        table.insert(self.spValue,{1000+i,value})
                    else
                        dump("debug bad")
                    end
                else
                    self.parallaxLayer:addChild(img,v.z or 1,cc.p(v.ratioX or 1,v.ratioY or 1),cc.p(v.posX,v.posY))
                end

                if self.cloudLevel-ScrollLevelNum>=v.runLevel then
                    img:resume()
                else
                    img:update(1)
                    img:pause()
                end

                -- local shape3 = cc.DrawNode:create()
                -- shape3:drawRect(cc.p(0,0),cc.p(v.width,v.height),cc.c4f(1,1,1,1))
                -- self.parallaxLayer:addChild(shape3,20,cc.p(v.ratioX or 1,v.ratioY or 1),cc.p(v.posX-v.oriX,v.posY-v.oriY))

                if v.tap then
                    table.insert(self.spTap,{rect=cc.rect(v.posX-v.oriX,v.posY-v.oriY,v.width,v.height),runLevel=v.runLevel,key=img:getTag(),getName=v.getName,run=(v.tapRun or v.run),ratioX=(v.ratioX or 1),ratioY=(v.ratioY or 1)})
                end
            end

        else
            if self.sp[i] ==true then
                for j=1,#self.spValue do
                   if self.spValue[j][1]==1000+i then
                       SchedulerManager:getInstance():stop(self.spValue[j][2])
                       table.remove(self.spValue,j)
                       break;
                   end
                end
                for b,v in ipairs(self.spTap) do
                   if v.key==1000+i then
                      table.remove(self.spTap,b)
                      break;
                   end
                end
                --  dump(#self.spTap)
                self.parallaxLayer:removeChild(self.parallaxLayer:getChildByTag(1000+i),true)
                self.sp[i]=false
            end

        end
    end

end

-- 初始化大地图和spine的偏差
function MainScene:mapInit()
    for i=1,#layout.frame do
        local info = layout.frame[i]
        local rect2= {};
        rect2.y=info[3][2]/info[4][2];
        rect2.height =info[6][2]/info[4][2];
        table.insert(info,rect2)
    end
    self.spineArr={}
     for i,v in ipairs(layout.animation) do
        local rect2= {};
        rect2.y=(v.posY-v.oriY)/(v.ratioY or 1)
        rect2.height =v.height/(v.ratioY or 1)
        table.insert(self.spineArr,rect2)

    end
end

function MainScene:rectIntersectsRect( rect1, rect2 ,contentScale)
    local intersect = not (
    -- rect1.x > rect2.x + rect2.width or
                    -- rect1.x + rect1.width < rect2.x         or
                    rect1.y > (rect2.y + rect2.height)* contentScale       or
                    rect1.y + rect1.height < rect2.y*contentScale )
    return intersect
end


function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
