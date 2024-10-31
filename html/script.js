let isOpen = false;
let isInputFocused = false;
const openMenuSound = new Audio('sound/open.mp3');
const hoverSound = new Audio('sound/hover.mp3');

let lastHoverSoundTime = 0;
const hoverSoundCooldown = 100;

openMenuSound.onerror = () => console.error('Error loading open sound.');
hoverSound.onerror = () => console.error('Error loading hover sound.');

function playOpenMenuSound() {
    openMenuSound.currentTime = 0;
    openMenuSound.play().catch(error => console.error('Error playing open sound:', error));
}

function playHoverSound() {
    const currentTime = Date.now();
    if (currentTime - lastHoverSoundTime >= hoverSoundCooldown) {
        hoverSound.currentTime = 0;
        hoverSound.play().catch(error => console.error('Error playing hover sound:', error));
        lastHoverSoundTime = currentTime;
    }
}

function openMenu(locations) {
    playOpenMenuSound();
    
    const menu = document.getElementById('menu');
    const list = document.getElementById('location-list');
    list.innerHTML = '';

    const existingH3 = menu.querySelector('h3');
    existingH3 && existingH3.remove();

    const buttons = menu.querySelectorAll('.delete-all-btn, .reset-vehicles-btn, .settings, .button-2');
    buttons.forEach(button => button.remove());

    locations.forEach((location, index) => {
        const li = document.createElement('li');
        li.textContent = `Zone ${index + 1}`;
        const optionsContainer = document.createElement('div');
        optionsContainer.style.display = 'none';

        const createInput = (type, placeholder, value, onInput) => {
            const input = document.createElement('input');
            input.type = type;
            input.placeholder = placeholder;
            input.value = value;
            input.oninput = onInput;
            input.onfocus = () => isInputFocused = true;
            input.onblur = () => isInputFocused = false;
            return input;
        };

        const modelInput = createInput('text', 'ENTER VEHICLE MODEL', location.selectedModel || '', 
                                       () => location.selectedModel = modelInput.value);
        const duplicationsInput = createInput('number', 'Number of duplications', location.selectedDuplications,
                                              () => location.selectedDuplications = parseInt(duplicationsInput.value) || 1);

        [modelInput, duplicationsInput].forEach(input => 
            input.addEventListener('keydown', event => {
                if (event.key === 'Enter') confirmSelection(index, modelInput.value, duplicationsInput.value);
            })
        );

        li.onclick = (event) => {
            event.stopPropagation();
            optionsContainer.style.display = !isInputFocused ? (optionsContainer.style.display === 'none' ? 'block' : 'none') : 'block';
        };

        li.onmouseover = playHoverSound;

        optionsContainer.append(modelInput, duplicationsInput);
        li.appendChild(optionsContainer);
        list.appendChild(li);        
    });

    const h3 = document.createElement('h3');
    h3.textContent = 'OTHER OPTIONS';
    menu.appendChild(h3);

    const deleteAllButton = document.createElement('button');
    deleteAllButton.classList.add('delete-all-btn');
    deleteAllButton.onclick = deleteAllVehicles;
    deleteAllButton.onmouseover = playHoverSound;
    menu.appendChild(deleteAllButton);

    const resetVehiclesButton = document.createElement('button');
    resetVehiclesButton.classList.add('reset-vehicles-btn');
    resetVehiclesButton.onclick = resetVehicles;
    resetVehiclesButton.onmouseover = playHoverSound;
    menu.appendChild(resetVehiclesButton);

    const button1 = document.createElement('button');
    button1.classList.add('settings');
    button1.onmouseover = playHoverSound;
    menu.appendChild(button1);

    const button2 = document.createElement('button');
    button2.classList.add('button-2');
    button2.onmouseover = playHoverSound;
    menu.appendChild(button2);

    menu.classList.add('active');
    menu.style.display = 'block';
    isOpen = true;
    document.addEventListener('keydown', handleKeyDown);
}

function resetVehicles() {
    fetch(`https://${GetParentResourceName()}/resetVehicles`, { method: 'POST' });
    closeMenu();
}

function closeMenu() {
    const menu = document.getElementById('menu');
    menu.classList.remove('active');
    playOpenMenuSound();

    menu.style.animation = 'slideOutRight 0.5s ease forwards';

    setTimeout(() => {
        menu.style.display = 'none';
        menu.style.animation = '';
    }, 500);

    isOpen = false;
    isInputFocused = false;
    fetch(`https://${GetParentResourceName()}/closeMenu`);
    document.removeEventListener('keydown', handleKeyDown);
}

function deleteAllVehicles() {
    fetch(`https://${GetParentResourceName()}/deleteAllVehicles`, { method: 'POST' });
    closeMenu();
}

function handleKeyDown(event) {
    if (event.key === 'Escape') return closeMenu();
    if (event.key === 'Backspace' && !isInputFocused) {
        const openOptions = document.querySelectorAll('#location-list div[style*="display: block"]');
        openOptions.length ? openOptions[openOptions.length - 1].style.display = 'none' : closeMenu();
    }
}

function confirmSelection(index, model, duplications) {
    duplications = Math.max(1, Math.min(parseInt(duplications) || 1, 12));
    fetch(`https://${GetParentResourceName()}/spawnVehicles`, {
        method: 'POST',
        body: JSON.stringify({ index, model, duplications }),
        headers: { 'Content-Type': 'application/json' }
    });
    closeMenu();
}

window.addEventListener('message', event => {
    if (event.data.action === 'openMenu') openMenu(event.data.locations);
});
