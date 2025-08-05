-- LockOnConfig ModuleScript
-- Place in: ReplicatedStorage > LockOnModules > LockOnConfig

local LockOnConfig = {}

-- Visual Settings
LockOnConfig.TARGET_DECAL_ID = "rbxassetid://123456789" -- Replace with your target marker decal ID
LockOnConfig.TARGET_MARKER_SIZE = Vector3.new(4, 4, 0.1)
LockOnConfig.TARGET_MARKER_TRANSPARENCY = 0.3
LockOnConfig.TARGET_MARKER_COLOR = Color3.fromRGB(255, 0, 0)

-- Camera Settings
LockOnConfig.CAMERA_ZOOM_FOV = 50 -- Field of view when locked on (default is 70)
LockOnConfig.CAMERA_ZOOM_SPEED = 0.3 -- How fast the camera zooms (0-1, lower is smoother)
LockOnConfig.CAMERA_FOLLOW_SPEED = 0.2 -- How smoothly camera tracks target

-- Targeting Settings
LockOnConfig.MAX_LOCK_DISTANCE = 100 -- Maximum distance to lock onto a target
LockOnConfig.LOCK_ANGLE_THRESHOLD = 45 -- Maximum angle from camera forward to consider a target
LockOnConfig.PRIORITY_VIEW_WEIGHT = 2 -- How much to prioritize targets in view vs just nearby
LockOnConfig.MIN_TARGET_SIZE = 0.5 -- Minimum HumanoidRootPart size to be targetable

-- Performance Settings
LockOnConfig.UPDATE_RATE = 0.016 -- Update rate in seconds (60 FPS)
LockOnConfig.TARGET_SCAN_RATE = 0.1 -- How often to scan for new targets when not locked

-- Input Settings
LockOnConfig.LOCK_ON_KEY = Enum.KeyCode.LeftControl

return LockOnConfig