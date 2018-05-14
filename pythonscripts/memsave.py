#!/usr/bin/env python
import os
import shutil
import sys


def get_device_path():
    '''
    () -> str

    Returns the path to the android device currently plugged in.
    '''
    name = os.listdir("/run/user/1000/gvfs/")[0]
    dp = "/run/user/1000/gvfs/{name}/Internal shared storage/".format(name=name)
    return dp

def del_old_ppsspp():
    """
    Remove the secondary saves for PSP
    """
    adir = get_device_path() + "PSP/SAVEDATA/"
    cdir = os.path.expanduser("~") + "/.config/ppsspp/PSP/SAVEDATA/"
    deldirs = [adir + x for x in os.listdir(adir) if x.endswith("DATA01")]
    deldirs += [cdir + x for x in os.listdir(cdir) if x.endswith("DATA01")]
    for d in deldirs:
        shutil.rmtree(d)


def replace_psp():
    """
    Replace the old ppsspp saves with new ones.
    """
    andpspdir = get_device_path() + "PSP/SAVEDATA/"
    compspdir = os.path.expanduser("~") + "/.config/ppsspp/PSP/SAVEDATA/"
    andfiles = [x for x in os.listdir(andpspdir) if x.endswith("DATA00")]
    anddest = [x.replace("DATA00", "DATA01") for x in andfiles]
    andfiles = [andpspdir + x for x in andfiles]
    anddest = [compspdir + x for x in anddest]
    comfiles = [x for x in os.listdir(compspdir) if x.endswith("DATA00")]
    comdest = [x.replace("DATA00", "DATA01") for x in comfiles]
    comfiles = [compspdir + x for x in comfiles]
    comdest = [andpspdir + x for x in comdest]
    for i, x in enumerate(andfiles):
        shutil.copytree(andfiles[i], anddest[i])
    for i, x in enumerate(comfiles):
        try:
            shutil.copytree(comfiles[i], comdest[i])
        except OSError:
            pass


def remove_old_saves():
    '''
    () -> None

    Remove the old saves located on the home computer as well as the android
    device.
    '''
    home = os.path.expanduser("~")
    if os.path.exists(home + "/.pcsx/memcards/card2.mcd"):
        os.remove(home + "/.pcsx/memcards/card2.mcd")
    if os.path.exists(get_device_path() + "epsxe/memcards/epsxe001.mcr"):
        os.remove(get_device_path() + "epsxe/memcards/epsxe001.mcr")
    base = get_device_path() + "/Download/saves/"
    # snes
    mobile_saves = [x for x in os.listdir(base) if x.endswith(".01.frz")]
    pc_saves = [x for x in os.listdir(home + "/Games/saves/")
                if x.endswith(".001")]
    for g in mobile_saves:
        os.remove(base + g)
    for g in pc_saves:
        os.remove(home + "/Games/saves/" + g)
    del_old_ppsspp()


def get_snes_saves():
    '''
    () -> None

    Grab all my snes file saves.
    '''
    home = os.path.expanduser("~")
    base = get_device_path() + "/Download/saves/"
    mobile_saves = [x for x in os.listdir(base) if x.endswith(".00.frz")]
    pc_saves = [x for x in os.listdir(home + "/Games/saves/")
                if x.endswith(".000")]
    return mobile_saves, pc_saves


def copy_over_saves():
    '''
    () -> None

    Copy the saves from home computer over to the android device and visa-versa.
    '''
    home = os.path.expanduser("~")
    base = get_device_path()
    if os.path.isfile(base + "epsxe/memcards/epsxe000.mcr"):
        shutil.copyfile(base + "epsxe/memcards/epsxe000.mcr",
                        home + "/.pcsx/memcards/card2.mcd")
    if os.path.isfile(home + "/.pcsx/memcards/card1.mcd"):
        shutil.copyfile(home + "/.pcsx/memcards/card1.mcd",
                    base + "epsxe/memcards/epsxe001.mcr")
    base = get_device_path() + "/Download/saves/"
    mobile_saves, pc_saves = get_snes_saves()
    for g in mobile_saves:
        shutil.copyfile(base + g,
                        home + "/Games/saves/" + g.replace(".00.frz", ".001"))
    for g in pc_saves:
        shutil.copyfile(home + "/Games/saves/" + g,
                    base + g.replace(".000", ".01.frz"))
    replace_psp()


if __name__ == "__main__":
    remove_old_saves()
    copy_over_saves()
