local Module = {}

Module.CreateRightHandIK = function(Character : Model)
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    --Create IK attachments--

    local RightHandIKGoal = Instance.new("Attachment")
    RightHandIKGoal.Name = "RightHandIKGoal"

    RightHandIKGoal.Parent = Character.UpperTorso

    local PoleR = Instance.new("Attachment")
    PoleR.Parent = HumanoidRootPart
    PoleR.Name = "PoleR"

    --~Constraints~--

    --Right Elbow Constraint
    local RightElbowConstraint = Instance.new("HingeConstraint")
    RightElbowConstraint.Visible = true
    RightElbowConstraint.Parent = Character.RightLowerArm
    RightElbowConstraint.Name = "RightElbowConstraint"

    local RightElbowConstraintAttachment0 = Instance.new("Attachment")
    RightElbowConstraintAttachment0.Parent = Character.RightUpperArm.RightElbowRigAttachment

    local RightElbowConstraintAttachment1 = Instance.new("Attachment")
    RightElbowConstraintAttachment1.Parent = Character.RightLowerArm.RightElbowRigAttachment

    RightElbowConstraintAttachment1.CFrame = RightElbowConstraintAttachment0.CFrame

    RightElbowConstraint.Attachment0 = RightElbowConstraintAttachment0
    RightElbowConstraint.Attachment1 = RightElbowConstraintAttachment1

    --Right Wrist Constraint
    local RightWristConstraint = Instance.new("BallSocketConstraint")
    RightWristConstraint.Parent = Character.RightHand
    RightWristConstraint.Name = "RightWristConstraint"

    local RightWristConstraintAttachment0 = Instance.new("Attachment")
    RightWristConstraintAttachment0.CFrame *= CFrame.Angles(0, math.rad(-180), math.rad(-90))
    RightWristConstraintAttachment0.Parent = Character.RightLowerArm.RightWristRigAttachment

    local RightWristConstraintAttachment1 = Instance.new("Attachment")
    RightWristConstraintAttachment1.Parent = Character.RightHand.RightWristRigAttachment

    RightWristConstraintAttachment1.CFrame = RightWristConstraintAttachment0.CFrame

    RightWristConstraint.Attachment0 = RightWristConstraintAttachment0
    RightWristConstraint.Attachment1 = RightWristConstraintAttachment1

    RightWristConstraint.LimitsEnabled = true
    RightWristConstraint.UpperAngle = 80

    --IK Control Set up--

    --Right Arm IK

    local IKControlR = Instance.new("IKControl")
    IKControlR.Name = "RightArmControl"
    IKControlR.Pole = PoleR
    IKControlR.Enabled = false

    IKControlR.ChainRoot = Character.RightUpperArm
    IKControlR.EndEffector = Character.RightHand

    IKControlR.Type = Enum.IKControlType.Transform
    IKControlR.Target = RightHandIKGoal
    IKControlR.Parent = Character.Humanoid

    return IKControlR
end

Module.CreateLeftHandIK = function(Character : Model)
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    --Create IK attachments--
    local LeftHandIKGoal = Instance.new("Attachment")
    LeftHandIKGoal.Name = "LeftHandIKGoal"

    LeftHandIKGoal.Parent = Character.RightHand

    local PoleL = Instance.new("Attachment")
    PoleL.Parent = HumanoidRootPart
    PoleL.Name = "PoleL"

    --~Constraints~--

    --Left Elbow Constraint
    local LeftElbowConstraint = Instance.new("HingeConstraint")
    LeftElbowConstraint.Visible = true
    LeftElbowConstraint.Parent = Character.LeftLowerArm
    LeftElbowConstraint.Name = "LeftElbowConstraint"

    local LeftElbowConstraintAttachment0 = Instance.new("Attachment")
    LeftElbowConstraintAttachment0.Parent = Character.LeftUpperArm.LeftElbowRigAttachment

    local LeftElbowConstraintAttachment1 = Instance.new("Attachment")
    LeftElbowConstraintAttachment1.Parent = Character.LeftUpperArm.LeftElbowRigAttachment

    LeftElbowConstraintAttachment1.CFrame = LeftElbowConstraintAttachment0.CFrame

    LeftElbowConstraint.Attachment0 = LeftElbowConstraintAttachment0
    LeftElbowConstraint.Attachment1 = LeftElbowConstraintAttachment1

    --Left Wrist Constraint
    local LeftWristConstraint = Instance.new("BallSocketConstraint")
    LeftWristConstraint.Parent = Character.LeftHand
    LeftWristConstraint.Name = "LeftWristConstraint"

    local LeftWristConstraintAttachment0 = Instance.new("Attachment")
    LeftWristConstraintAttachment0.CFrame *= CFrame.Angles(0, math.rad(-180), math.rad(-90))
    LeftWristConstraintAttachment0.Parent = Character.LeftLowerArm.LeftWristRigAttachment

    local LeftWristConstraintAttachment1 = Instance.new("Attachment")
    LeftWristConstraintAttachment1.Parent = Character.LeftHand.LeftWristRigAttachment

    LeftWristConstraintAttachment1.CFrame = LeftWristConstraintAttachment0.CFrame

    LeftWristConstraint.Attachment0 = LeftWristConstraintAttachment0
    LeftWristConstraint.Attachment1 = LeftWristConstraintAttachment1

    LeftWristConstraint.LimitsEnabled = true
    LeftWristConstraint.UpperAngle = 80

    --Left Arm IK
    local IKControlL = Instance.new("IKControl")
    IKControlL.Name = "LeftArmControl"
    IKControlL.Pole = PoleL
    IKControlL.Enabled = false

    IKControlL.ChainRoot = Character.LeftUpperArm
    IKControlL.EndEffector = Character.LeftHand

    IKControlL.Type = Enum.IKControlType.Transform
    IKControlL.Target = LeftHandIKGoal
    IKControlL.Parent = Character.Humanoid

    return IKControlL
end

return Module