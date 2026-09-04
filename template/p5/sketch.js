// {{TITLE}}
//
// Every run looks the same because of this seed. Change the number to get a
// different variation of the same idea.
const SEED = {{SEED}};

function setup() {
  createCanvas(windowWidth, windowHeight);
  randomSeed(SEED);
  noiseSeed(SEED);
}

function draw() {
  background(20);
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}
