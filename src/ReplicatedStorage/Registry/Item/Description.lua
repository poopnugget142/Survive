local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")
local Enums = require(ReplicatedScripts.Registry.Enums)
local Item = Enums.Item

return {
    --~==GUNS==~--

    --~/Handguns/~--

    --/Semi Automatic Pistols/--

    [Item["Glock 17"]] =
    [[
    9mm Semi-Automatic Handgun from Austria, famous for its reliability. While its sriker-fired design makes it less accurate than the 
    Berreta M9, it makes up for this by allowing high capacity magazines.
    ]]
    
    ;[Item["Berreta M9A1"]] =
    [[
    9mm Semi-Automatic Handgun from Italy, famous for its double to single action trigger mechanism. More accurate than the Glock and compatiable
    with supressors, two are often seen in the hands of action heroes.
    ]]

    ;[Item["Colt M1911"]] =
    [[    
    .45 Caliber Semi-Automatic Handgun from the United States, considered the first modern Autoloading Handgun. Designed in 1911, as the name
    implies, it survied service in both World Wars, and will likely only be discontinued <i>when humans are.</i> 
    ]]

    ;[Item["H&K Mk.23"]] =
    [[
    .45 Caliber Semi-Automatic Handgun from Germany, famous for its use by special military services. Accurate, powerful, generously large
    and out-of-the-box compatiable with suppressors, its no wonder why it's been used by those who perfer to lurk in the shadows. 
    ]]
    ;[Item["FN Five-seveN"]] =
    [[
    5.7mm Semi-Automatic Handgun from Belgium, famous for its armor penetrating capabilities. With 20 rounds of the 5.7x28mm cartridge, the same as the 
    P90, the Five-seveN is a perfect tool for those who require armor penetration on a size budget. 
    ]]

    --/Revolvers/--
    ;[Item["S&W Model 10"]] =
    [[
    .38 Caliber Double-Action Revolver from the United States, holds the record for the most commercially succesful revolver in American history.
    Moderately powerful, of moderate size, it comes from a more moderate time. 
    ]]

    ;[Item["Colt Python"]] =
    [[
    .357 Magnum Double-Action Revolver from the United States, famous for its powerful cartridge, and stylish design. It is also compatiable 
    with .38 rounds. High recoil remains a worthy tradeoff for high stopping power. 
    ]]

    ;[Item["Colt Anaconda"]] =
    [[
    .44 Magnum Double-Action Revolver from the United States, known as the even bigger brother of the Colt Python. At one time, the .44 was
    the most powerful handgun cartridge in the world; despite modern technology, its still not far off. 

    ]]
    --~/Shotguns/~--

    ;[Item["Remington 870"]] =
    [[
    12 Gauge Pump-Action Shotgun from the United States, known as the most ubiquitous shotgun in the country. Powerful, relaible, and iconic, a classic
    design that remains highly effective. 
    ]]

    ;[Item["Serbu Super Shorty"]] =
    [[
    12 Gauge Pump-Action Shotgun from the United States, known for its incredibly small size. It has a measly magazine capacity of 2 rounds, but its compact 
    nature and breaching muzzle device make it ideal as a secondary weapon. 
    ]]

    --~/Submachine Guns/~--

    ;[Item["Steyr TMP"]] =
    [[
    9mm Submachine Gun from Austria, famous for its compact size. Features Semi and Fully-Automatic firing modes. While the lack of a stock noticably 
    decreases its accuracy and recoil control, this is made up for by the extra room in your backpack. 
    ]]

    ;[Item["H&K UMP"]] =
    [[
    .45 Caliber Submachine Gun from Germany, often seen as the cheaper alternative to its big brother, the MP5. Features Semi-Automatic, Fully-Automatic,
    and 2-Round Burst firing modes. Your enemies wont be able to criticize its polymer construction when they're pockmarked with .45 caliber holes. 
    ]]

    ;[Item["FN P90"]] =
    [[
    5.7mm Submachine Gun (or Personal Defense Weapon) from Belgium, famous for its armor penetrating capabilities. Features Semi and Fully-Automatic firing modes.
    An odd looking piece, but its incredible 50-round capacity and top of the line armor penetration among Submachine Guns make criticism seem childish. 
    ]]
}