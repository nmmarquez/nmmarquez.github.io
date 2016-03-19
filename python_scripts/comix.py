'''
This iteration of comix stripper uses the retrieve module which tends to crash
a lot less than urllib when grabbing jpeg images or just large files in 
general. I started writing doc strings but haven't finished. Currently the
program has to create a directory called Comix in your home directory in order
to work and it only works on Mac, Linux, and other Unix based systems. Sorry
Windows. Additionally the program only works with the website mangahere.co
and is pretty dependent on their html schema. The base directory that the
program asks for i.e. the comic URL is the one that lists all the issues of a
particular comic.
'''
import os, requests, zipfile, shutil, time, thread, errno, signal
from functools import wraps
from lxml import html


home = os.path.join(os.path.expanduser("~"), "Comix")

class TimeoutError(Exception):
    pass

def timeout(seconds=10, error_message=os.strerror(errno.ETIME)):
    def decorator(func):
        def _handle_timeout(signum, frame):
            raise TimeoutError(error_message)

        def wrapper(*args, **kwargs):
            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(seconds)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wraps(func)(wrapper)

    return decorator


def tranBool(response):
    '''
    (str) -> bool

    Translate a single string to a boolean response using common set of words
    that are often used to denote an affirmative response.
    '''
    affirmative = ['t', 'true', 'yes', 'y', '1', 'yeah', 'yup', 'fo sho']
    return response.lower() in affirmative


def pstrip(response):
    '''
    (str) -> str

    Remove the trailing forward slash from a URL if it is there.
    '''
    if response[-1] == '/':
        return response[:-1]
    else:
        return response

    
def baseEXT(add):
    '''
    (str) -> str, str
    Given a URL returns the base html from which information is obtained such
    as the number of comics and the links where they are found as well as the
    name of the comic to be used as a directory name.
    '''
    return '/'.join(add.split('/')[:-2]), add.split('/')[-1]


def readMeta():
    '''
    (None) -> str

    Read a URL from the hidden file in the base Comix directory.
    '''
    f = open(os.path.join(home, ".comixMeta.txt"), 'r')
    temp = f.readline().strip()
    f.close()
    return temp


def writeMeta(URL):
    '''
    (str) -> None

    Write a URL from the hidden file in the base Comix directory.
    '''
    f = open(os.path.join(home, ".comixMeta.txt"), 'w')
    f.writelines(URL)
    f.close()


def input_thread(L):
    '''
    (list) -> None

    Helper function used to cease the program after the current comic is
    finished downloading.
    '''
    raw_input()
    L.append(None)


def write_img(url_, file_):
    '''
    (str, str) -> None

    given a url and file write the image from the URL to the file.
    '''
    with open(file_, 'wb') as handle:
        response = requests.get(url_, stream=True)

        while not response.ok:
            print "Something fucked up retrying"
            response = requests.get(url_, stream=True)

        for block in response.iter_content(1024):
            if not block:
                break

            handle.write(block)


def intro():
    if not os.path.isdir(home):
        os.mkdir(home)
    print 'Welcome to Comic Stripper!\n'
    print 'Is this a download session?\n'
    download = tranBool(raw_input('> '))
    cont = False
    if os.path.exists(os.path.join(home, ".comixMeta.txt")):
        print 'The last comic url you used was %s,\n' % readMeta()
        print 'Would you like to continue that session?'
        cont = tranBool(raw_input('> '))
    if cont:
        add = readMeta()
    else:
        print 'What is the URL for the comics?\n'
        add = pstrip(raw_input('> '))
    writeMeta(add)
    base, comic = baseEXT(add)
    path = os.path.join(home, comic)
    if download:
        print 'Which number comic would you like to start with?'
        cNum = int(raw_input('> ')) - 1
        return download, add, base, comic, cNum, path
    else:
        return download, add, base, comic, None, path


# make base directory

def makePath(comic):
    path = os.path.join(home, comic)
    try:
        os.makedirs(path)
        print 'Base Directory Created!'
    except:
        print 'Base Directory Already there!'


# get base html

def getHTML(url):
    f = requests.get(url)
    return html.fromstring(f.text)


# get each chapters html

def getCH(baseHTML, add, base):
    comic = os.path.normpath (add).split ('/') [-1]
    chap = [ch.get ('href') [0:-1] for ch in baseHTML.xpath
            ('//a[@class="color_0077"]') if comic in ch.get('href')]
    return [ch if ch[0] == 'h' else base + ch for ch in chap][::-1]

# build a directory with jpeg images

def makeChDir(chapURL, comic):
    keyPh = 'var total_pages = '
    ext = chapURL.split('/c')[-1].zfill(3)
    nDir = os.path.join(home, comic, "c"+ext)
    if os.path.exists(nDir + '.zip') or os.path.exists(nDir + '.cbz'):
        print nDir + " already zipped!!!"; return
    try:
        os.makedirs(nDir)
    except:
        print nDir + " directory is already there!!!"; return
    tTree = getHTML (chapURL)
    js = [sc for sc in tTree.xpath ('//script[@type="text/javascript"]/text()')
          if keyPh in sc] [0]
    st = js.index(keyPh) + len (keyPh)
    num = int(js[st:].split(' ') [0])
    for i in range(1,num + 1):
        tries = 0
        success = False
        while tries < 10 and not success:
            try:
                get_image(i, chapURL, nDir)
                success = True
            except:
                tries += 1
    print nDir + " successfully created!!"

@timeout(20)
def get_image(i, chapURL, nDir):
    page = requests.get(''.join([chapURL, '/', str(i), '.html']))
    stTree = html.fromstring(page.text)
    jFile = [img.get('src') for img in stTree.xpath('//img')][0]
    write_img(jFile, os.path.join(nDir, str(i).rjust(3, '0') + '.jpg'))


# make a function that builds multiple chapter directries

def makeAllCh(baseHTML, cNum, add, base, comic):
    cURL = getCH(baseHTML, add, base)
    L = []
    thread.start_new_thread(input_thread, (L,))
    for u in cURL[cNum:]:
        time.sleep(.1)
        if L:
            break
        makeChDir(u, comic)
    return

# zipping function that zips a directory idk why this isnt a thing already

def zipdir(path, zip):
    for root, dirs, files in os.walk(path):
        for f in files:
            zip.write(os.path.join(root, f))

# zip all directories in a path

def zipAll(path):
    dirs = [os.path.join(path, d) for d in os.listdir(path)
               if not d.startswith('.') and os.path.isdir(path + '/' + d)]
    for d in dirs:
        tempZ = zipfile.ZipFile(d + '.zip', 'w')
        zipdir(d, tempZ)
        shutil.rmtree(d)
    return

# convert zip files to cbz files

def conv2CBZ(path):
    for z in [os.path.join(path, f) for f in os.listdir(path) if f.endswith('.zip')]:
        os.rename(z, z[:-3] + 'cbz')
    return


# The function that does it all

def doAll():
    download, add, base, comic, cNum, path = intro()
    makePath(comic)
    if download:
        baseHTML = getHTML(add)
        makeAllCh(baseHTML, cNum, add, base, comic)
    zipAll(path)
    conv2CBZ(path)
    print 'See yah!'
    return    

doAll()
