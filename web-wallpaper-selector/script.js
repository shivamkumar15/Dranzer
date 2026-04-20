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
    background.style.backgroundImage = `url('${selectedWallpaper.path}')`;
    
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
