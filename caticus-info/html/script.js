let playerBoxes = {};

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updatePlayer') {
        updatePlayerBox(data.data);
    } else if (data.action === 'hideAll') {
        hideAllBoxes();
    }
});

function hideAllBoxes() {
    for (let id in playerBoxes) {
        playerBoxes[id].remove();
    }
    playerBoxes = {};
}

function updatePlayerBox(data) {
    let box = playerBoxes[data.serverId];
    
    if (!box) {
        box = createPlayerBox(data);
        document.body.appendChild(box);
        playerBoxes[data.serverId] = box;
    }
    
    // Update position using the same coordinates as ID script
    box.style.left = `${data.position.x}px`;
    box.style.top = `${data.position.y}px`;
    
    // Update content
    updateBoxContent(box, data);
}

function createPlayerBox(data) {
    const box = document.createElement('div');
    box.className = 'player-box';
    updateBoxContent(box, data);
    return box;
}

function updateBoxContent(box, data) {
    const playerData = data.playerData || {};
    
    box.innerHTML = `
        <div class="info-container">
            <div class="avatar-section">
                <img src="${data.mugshot}" alt="Player Mugshot">
            </div>
            <div class="info-section">
                <div class="info-row">
                    <span class="label">Character:</span>
                    <span class="value">${playerData.charName || 'Unknown'}</span>
                </div>
                <div class="info-row">
                    <span class="label">Steam:</span>
                    <span class="value">${data.steamName}</span>
                </div>
                <div class="info-row">
                    <span class="label">ID:</span>
                    <span class="value">${data.serverId}</span>
                </div>
                <div class="health-bar">
                    <div class="health-fill" style="width: ${data.health}%"></div>
                </div>
                <div class="money-info">
                    <div class="info-row">
                        <span class="label">Cash:</span>
                        <span class="value money-green">$${(playerData.cash || 0).toLocaleString()}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Bank:</span>
                        <span class="value money-gold">$${(playerData.bank || 0).toLocaleString()}</span>
                    </div>
                </div>
            </div>
        </div>
    `;
} 