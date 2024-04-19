// Function to update visualization based on incoming data
function updateTagPosition(data) {
    const container = document.getElementById('container');
    const tag = document.getElementById('tag');

    // Beacon positions (x, y)
    const beaconPositions = {
        "1783": {x: 100, y: 100},
        "1782": {x: 300, y: 100},
        "1781": {x: 100, y: 300},
        "1784": {x: 300, y: 300}
    };

    const positions = data.links.map(link => beaconPositions[link.A]);
    const distances = data.links.map(link => parseFloat(link.R)); // Convert R to float

    // Trilateration algorithm (assuming 2D space)
    const sumWeights = distances.reduce((acc, val) => acc + (1 / val), 0);
    let x = 0, y = 0;
    for (let i = 0; i < positions.length; i++) {
        const weight = (1 / distances[i]) / sumWeights;
        x += positions[i].x * weight;
        y += positions[i].y * weight;
    }

    // Update tag position
    tag.style.left = x + 'px';
    tag.style.top = y + 'px';
}

// Export the function to be used in app.js
module.exports = { updateTagPosition };
