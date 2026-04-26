const basePath = window.location.pathname.includes('.local/share') ? '../wallpapers/' : '../';

const wallpapers = [
    { name: 'BurningCerbrus.png', path: basePath + 'BurningCerbrus.png' },
    { name: 'Dracel.png', path: basePath + 'Dracel.png' },
    { name: 'Dragoon.png', path: basePath + 'Dragoon.png' },
    { name: 'Dranzer.png', path: basePath + 'Dranzer.png' },
    { name: 'Drigger.png', path: basePath + 'Drigger.png' },
    { name: 'Galeon.png', path: basePath + 'Galeon.png' }
];

let selectedIndex = Math.floor(wallpapers.length / 2);

const carousel = document.getElementById('carousel');
const background = document.getElementById('background');
const backgroundNext = document.getElementById('background-next');
const overlay = document.querySelector('.overlay');

let currentBackground = background;
let nextBackground = backgroundNext;
let currentBackgroundPath = '';
let backgroundTransitionToken = 0;
let previousSelectedIndex = selectedIndex;

const backgroundSlideDistance = 40;
const backgroundTransitionDurationMs = 400;
const brightnessPulseDurationMs = 450;

let brightnessPulseToken = 0;

// Config
const cardWidth = 180;
const gap = 30;
const itemSize = cardWidth + gap;

function init() {
    // Generate cards
    wallpapers.forEach((wp, index) => {
        const wrapper = document.createElement('div');
        wrapper.className = 'card-wrapper';
        wrapper.dataset.index = index;
        
        const card = document.createElement('div');
        card.className = 'card';
        card.style.backgroundImage = `url('${wp.path}')`;
        
        const label = document.createElement('div');
        label.className = 'label';
        // Remove extension for cleaner look
        label.textContent = wp.name.replace('.png', '').replace('.jpg', '');
        
        wrapper.appendChild(card);
        wrapper.appendChild(label);
        
        // Click to select
        wrapper.addEventListener('click', () => {
            if (selectedIndex !== index) {
                selectedIndex = index;
                updateSelection();
            }
        });
        
        carousel.appendChild(wrapper);
    });
    
    updateSelection();
}

function updateSelection() {
    const wrappers = document.querySelectorAll('.card-wrapper');
    
    wrappers.forEach((wrapper, index) => {
        wrapper.classList.remove('selected', 'adjacent');
        
        if (index === selectedIndex) {
            wrapper.classList.add('selected');
        } else if (index === selectedIndex - 1 || index === selectedIndex + 1) {
            wrapper.classList.add('adjacent');
        }
    });
    
    // Update background
    const selectedWallpaper = wallpapers[selectedIndex];
    const direction = Math.sign(selectedIndex - previousSelectedIndex);
    setBackground(selectedWallpaper.path, direction);
    previousSelectedIndex = selectedIndex;
    
    // Calculate translation to keep selected item in center
    // Assuming container is perfectly centered, we just shift by the offset
    // Since initially all items are laid out from center (wait, display flex content center).
    // Let's rethink layout.
    // Actually, if we use translateX, we need to know the offset from the middle.
    // Middle item index in a centered flex container is (wallpapers.length - 1) / 2
    // The visual center is 0. 
    const centerIndex = (wallpapers.length - 1) / 2;
    const diff = centerIndex - selectedIndex;
    const translateX = diff * itemSize;
    
    carousel.style.transform = `translateX(${translateX}px)`;
}

function setBackground(path, direction = 0) {
    if (!path || currentBackgroundPath === path) {
        return;
    }

    if (!currentBackgroundPath) {
        currentBackgroundPath = path;
        currentBackground.style.backgroundImage = `url('${path}')`;
        currentBackground.style.setProperty('--bg-shift', '0px');
        currentBackground.style.setProperty('--bg-exit-shift', '0px');
        currentBackground.classList.add('visible');
        return;
    }

    const token = ++backgroundTransitionToken;
    const incomingShift = direction === 0 ? 0 : (direction > 0 ? backgroundSlideDistance : -backgroundSlideDistance);
    const outgoingShift = -incomingShift;

    nextBackground.style.backgroundImage = `url('${path}')`;
    nextBackground.style.setProperty('--bg-shift', `${incomingShift}px`);
    nextBackground.style.setProperty('--bg-exit-shift', '0px');
    nextBackground.classList.remove('exiting');

    currentBackground.style.setProperty('--bg-exit-shift', `${outgoingShift}px`);
    currentBackground.classList.add('exiting');
    triggerBrightnessPulse();
    nextBackground.classList.add('visible');
    currentBackground.classList.remove('visible');

    window.setTimeout(() => {
        if (token !== backgroundTransitionToken) {
            return;
        }

        const previousBackground = currentBackground;
        currentBackground = nextBackground;
        nextBackground = previousBackground;

        currentBackgroundPath = path;
        currentBackground.classList.remove('exiting');
        currentBackground.style.setProperty('--bg-shift', '0px');
        currentBackground.style.setProperty('--bg-exit-shift', '0px');

        nextBackground.classList.remove('visible');
        nextBackground.classList.remove('exiting');
        nextBackground.style.backgroundImage = '';
        nextBackground.style.setProperty('--bg-shift', '0px');
        nextBackground.style.setProperty('--bg-exit-shift', '0px');
    }, backgroundTransitionDurationMs);
}

function triggerBrightnessPulse() {
    if (!overlay) {
        return;
    }

    const token = ++brightnessPulseToken;
    overlay.classList.remove('pulse');
    void overlay.offsetWidth;
    overlay.classList.add('pulse');

    window.setTimeout(() => {
        if (token !== brightnessPulseToken) {
            return;
        }

        overlay.classList.remove('pulse');
    }, brightnessPulseDurationMs);
}

// Keyboard navigation
window.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === 'l') {
        if (selectedIndex < wallpapers.length - 1) {
            selectedIndex++;
            updateSelection();
        }
    } else if (e.key === 'ArrowLeft' || e.key === 'h') {
        if (selectedIndex > 0) {
            selectedIndex--;
            updateSelection();
        }
    } else if (e.key === 'Enter') {
        document.title = "SELECTED:" + wallpapers[selectedIndex].name;
    } else if (e.key === 'Escape') {
        document.title = "CLOSE";
    }
});

// Initialize
init();
