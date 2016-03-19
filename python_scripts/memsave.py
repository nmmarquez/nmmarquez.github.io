
import os, sys, shutil


def get_device_path():
    '''
    () -> str
    
    Returns the path to the android device currently plugged in. 
    '''
    name = os.listdir("/run/user/1000/gvfs/")[0]
    return "/run/user/1000/gvfs/{name}/Internal storage/".format(name=name)


def remove_old_saves():
    '''
    () -> None

    Remove the old saves located on the home computer as well as the android
    device.
    ''' 
    if os.path.exists("/home/neal/.pcsx/memcards/card2.mcd"):
        os.remove("/home/neal/.pcsx/memcards/card2.mcd")
    if os.path.exists(get_device_path() + "epsxe/memcards/epsxe001.mcr"):
        os.remove(get_device_path() + "epsxe/memcards/epsxe001.mcr")
    base = get_device_path() + "/Download/saves/"
    mobile_saves = [x for x in os.listdir(base) if x.endswith(".01.frz")]
    pc_saves = [x for x in os.listdir("/home/neal/Games/saves/") if x.endswith(".001")]
    for g in mobile_saves:
        os.remove(base + g)
    for g in pc_saves:
        os.remove("/home/neal/Games/saves/" + g)

   
def get_snes_saves():
    '''
    () -> None
    
    Grab all my snes file saves.
    '''
    base = get_device_path() + "/Download/saves/"
    mobile_saves = [x for x in os.listdir(base) if x.endswith(".00.frz")]
    pc_saves = [x for x in os.listdir("/home/neal/Games/saves/") if x.endswith(".000")]
    return mobile_saves, pc_saves

        
def copy_over_saves():
    '''
    () -> None

    Copy the saves from home computer over to the android device and visa-versa.
    '''
    base = get_device_path()
    shutil.copyfile(base + "epsxe/memcards/epsxe000.mcr",
                "/home/neal/.pcsx/memcards/card2.mcd")
    shutil.copyfile("/home/neal/.pcsx/memcards/card1.mcd",
                base + "epsxe/memcards/epsxe001.mcr")
    base = get_device_path() + "/Download/saves/"
    mobile_saves, pc_saves = get_snes_saves()
    for g in mobile_saves:
        shutil.copyfile(base + g, 
                    "/home/neal/Games/saves/" + g.replace(".00.frz", ".001"))
    for g in pc_saves:
        shutil.copyfile("/home/neal/Games/saves/" + g,
                    base + g.replace(".000", ".01.frz"))


if __name__ == "__main__":
    remove_old_saves()
    copy_over_saves()



