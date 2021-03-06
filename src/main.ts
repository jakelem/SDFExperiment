import {vec3, vec4, mat4, mat3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Mesh from './geometry/Mesh';
import LSystem from './geometry/LSystem';
import Orchids from './geometry/Orchids';
// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  iterations: 4,
  'Color A 1': "#54cd7f",
  'Color A 2': "#4ecd82",
  'Texture A': 2.0,
  'Texture A Shape': 1.0,

  'Color B 1': "#cce8c8",
  'Color B 2': "#bbdcb9",
  'Texture B': 2.0,
  'Texture B Shape': 1.0,

  'Eye Color': "#89856e",
  'Body Size': 1.9,
  'Head Size': 1.2,
  'Limb Size': 1.2,
  'Digit Size': 0.6,

  'Head Sharpness': 1.0,

  'Eye Size': 0.43,
  'Pupil Size': 0.28,
  'Pupil Shape': 0.1,
  'Shaded': true,
  'Shadows': false,
  'Show Normals': false,
  'Colored': true,
  'Debug': {
    'Orientate': false,
  },
  'Species' : "White's Tree Frog",
  'Randomize!': loadRandom, // A function pointer, essentially
};

let square: Square;
let m_mesh: Mesh;
let gui : DAT.GUI;
function loadObjs() {
}


function getBodyColors() {
  return hexToRGB(controls["Color A 1"]).concat(hexToRGB(controls["Color A 2"]))
  .concat(hexToRGB(controls["Color B 1"]))
  .concat(hexToRGB(controls["Color B 2"]))
  .concat(hexToRGB(controls["Eye Color"]));
  
}


function getBodySizes() {
  return [controls["Body Size"], 
  controls["Head Size"], 
  controls["Eye Size"], 
  0.3 - controls["Pupil Size"],
  controls["Pupil Shape"],
controls['Texture A'],
controls['Texture B'], 
controls['Texture A Shape'],
controls['Texture B Shape'], 
controls["Limb Size"],
controls["Digit Size"]];


}


function getFlags() {
  return [controls["Shaded"] ? 1 :0,controls["Shadows"] ? 1 : 0
  , controls["Show Normals"] ? 1 : 0 , controls["Colored"] ? 1 : 0, controls["Debug"]["Orientate"] ? 1 : 0];
}

function hexToRGB(hex : any) {
  if(typeof hex !== 'string') {
    return hex;
  }
  let res = [parseInt(hex.substring(1, 3), 16), parseInt(hex.substring(3, 5), 16), parseInt(hex.substring(5), 16)];
  return res;
}


let xSubs = 5;
let ySubs = 3;
let zSubs = 3;


function loadScene() {

  m_mesh = new Mesh('/geo/feather.obj',vec3.fromValues(0, 1, 0), vec3.fromValues(1, 1, 1), vec3.fromValues(98, 0, 0));
  //m_mesh.create();
  //m_mesh.center = vec4.fromValues(0, 1, 2, 1);
  square = new Square(vec3.fromValues(0, 0, 0));

  square.create();
}

function randomRange(m1 : number, m2 : number) {
  let range = m2 - m1;
  return m1 + range * Math.random();
}

function randomColor() {
  return '#' + Math.floor(Math.random()*16777215).toString(16);

}


function updateGUI(g : DAT.GUI) {
  for (let i in g.__controllers) {
    g.__controllers[i].updateDisplay();
  }

  for (let i in g.__folders) {
    updateGUI(g.__folders[i]);
  }
}

function loadRandom() {
  controls['Body Size'] = randomRange(1.4, 2.6);
  controls['Head Size'] = randomRange(1.0, 1.7);
  controls['Limb Size'] = randomRange(0.9, 1.7);
  controls['Digit Size'] = randomRange(0.2, 1.2);

  controls['Eye Size'] = randomRange(0.35, 0.6);
  controls['Pupil Size'] = randomRange(0.2, 0.3);
  controls['Pupil Shape'] = randomRange(-0.1, 0.1);


  controls['Color A 1'] = randomColor();
  controls['Color A 2'] = randomColor();
  controls['Color B 1'] = randomColor();
  controls['Color B 2'] = randomColor();
  controls['Eye Color'] = randomColor();

  controls['Texture A'] = randomRange(0.2, 15);
  controls['Texture A Shape'] = randomRange(0.5, 2.0);
  controls['Texture B'] = randomRange(0.2, 15);
  controls['Texture B Shape'] = randomRange(0.5, 2.0);

  updateGUI(gui);

}


/** 
 * 
 * 
 * 
 *   'Color A 1': "#54cd7f",
  'Color A 2': "#4ecd82",
  'Texture A': 2.0,
  'Texture A Shape': 1.0,

  'Color B 1': "#cce8c8",
  'Color B 2': "#bbdcb9",
  'Texture B': 2.0,
  'Texture B Shape': 1.0,

  'Eye Color': "#89856e",
  'Body Size': 1.9,
  'Head Size': 1.2,
  'Limb Size': 1.2,
  'Digit Size': 0.6,

  'Head Sharpness': 1.0,

  'Eye Size': 0.43,
  'Pupil Size': 0.28,
  'Pupil Shape': 0.1,

*/
function whitesTree() {
  controls['Body Size'] = 1.9;
  controls['Head Size'] = 1.2;
  controls['Limb Size'] = 1.2;
  controls['Digit Size'] = 0.6;

  controls['Eye Size'] = 0.43;
  controls['Pupil Size'] = 0.28;
  controls['Pupil Shape'] = 0.1;


  controls['Color A 1'] = "#54cd7f";
  controls['Color A 2'] = "#6eff98";
  controls['Color B 1'] = "#cce8c8";
  controls['Color B 2'] = "#bbdcb9";
  controls['Eye Color'] = "#89856e";

  controls['Texture A'] = 2.0;
  controls['Texture A Shape'] = 1;
  controls['Texture B'] = 2.0;
  controls['Texture B Shape'] = 1;

}



function tomato() {
  controls['Body Size'] = 2.2;
  controls['Head Size'] = 1.2;
  controls['Limb Size'] = 1.2;
  controls['Digit Size'] = 0.2;

  controls['Color A 1'] = "#980000";
  controls['Color A 2'] = "#af3300";
  controls['Texture A'] = 3.3;
  controls['Texture A Shape'] = 0.5;

  controls['Color B 1'] = "#de1a00";
  controls['Color B 2'] = "#5c0707";
  controls['Texture B'] = 5.6;
  controls['Texture B Shape'] = 0.9;

  controls['Eye Color'] = "#66510e";
  controls['Eye Size'] = 0.45;
  controls['Pupil Size'] = 0.21;
  controls['Pupil Shape'] = 0.0;

}

function blueDart() {
  controls['Body Size'] = 1.6;
  controls['Head Size'] = 1;
  controls['Limb Size'] = 0.9;
  controls['Digit Size'] = 0.62;

  controls['Color A 1'] = "#004787";
  controls['Color A 2'] = "#000000";
  controls['Texture A'] = 6.1;
  controls['Texture A Shape'] = 2.2;

  controls['Color B 1'] = "#0b1c46";
  controls['Color B 2'] = "#054093";
  controls['Texture B'] = 6.5;
  controls['Texture B Shape'] = 2.6;

  controls['Eye Color'] = "#000000";
  controls['Eye Size'] = 0.35;
  controls['Pupil Size'] = 0.3;
  controls['Pupil Shape'] = 0.0;

}


function redEyed() {
  controls['Body Size'] = 1.4;
  controls['Head Size'] = 1.1;
  controls['Limb Size'] = 0.7;
  controls['Digit Size'] = 1.0;

  controls['Color A 1'] = "#7dcd52";
  controls['Color A 2'] = "#9bd489";
  controls['Texture A'] = 0.2;
  controls['Texture A Shape'] = 1.6;

  controls['Color B 1'] = "#f5f5f5";
  controls['Color B 2'] = "#cdcdcd";
  controls['Texture B'] = 1.7;
  controls['Texture B Shape'] = 5.0;

  controls['Eye Color'] = "#af3333";
  controls['Eye Size'] = 0.45;
  controls['Pupil Size'] = 0.25;
  controls['Pupil Shape'] = -0.1;

}


function amazonMilk() {
  controls['Body Size'] = 1.5;
  controls['Head Size'] = 1;
  controls['Limb Size'] = 0.9;
  controls['Digit Size'] = 0.62;

  controls['Eye Size'] = 0.4;
  controls['Pupil Size'] = 0.28;
  controls['Pupil Shape'] = 0.06;


  controls['Color A 1'] = "#cce5ed";
  controls['Color A 2'] = "#273428";
  controls['Color B 1'] = "#273428";
  controls['Color B 2'] = "#87d3eb";
  controls['Eye Color'] = "#c0a096";

  controls['Texture A'] = 2.0;
  controls['Texture A Shape'] = 2.3;
  controls['Texture B'] = 2.8;
  controls['Texture B Shape'] = 2.8;

}


function updateSpecies() {
  if(controls["Species"] == "White's Tree") {
    whitesTree();
  } else if(controls["Species"] == "Amazon Milk") {
    amazonMilk();
  } else if(controls["Species"] == "Blue Dart") {
    blueDart();
  } else if(controls["Species"] == "Red Eyed Tree") {
    redEyed();
  } else if(controls["Species"] == "Tomato") {
    tomato();
  }

  updateGUI(gui);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  gui = new DAT.GUI();
  gui.add(controls, 'Randomize!');
  gui.add(controls, 'Species', ["White's Tree",'Amazon Milk','Blue Dart', 'Red Eyed Tree', 'Tomato']).onChange(updateSpecies);

  gui.add(controls, 'Body Size', 1.4, 3).step(0.1);
  gui.add(controls, 'Head Size', 0.6, 2).step(0.1);
  gui.add(controls, 'Limb Size', 0.6, 2).step(0.1);
  gui.add(controls, 'Digit Size', 0.2, 1.2).step(0.1);

  let upbody = gui.addFolder("Upper Body Texture");

  upbody.addColor(controls, 'Color A 1');
  upbody.addColor(controls, 'Color A 2');
  upbody.add(controls, 'Texture A', 0.2, 15.0).step(0.1);
  upbody.add(controls, 'Texture A Shape', 0.0, 5.0).step(0.05);

  let loBod = gui.addFolder("Lower Body Texture");

  loBod.addColor(controls, 'Color B 1');
  loBod.addColor(controls, 'Color B 2');
  loBod.add(controls, 'Texture B', 0.0, 15.0).step(0.05);
  loBod.add(controls, 'Texture B Shape', 0.0, 5.0).step(0.05);

  let eyes = gui.addFolder("Eyes");
  eyes.addColor(controls, 'Eye Color');
  eyes.add(controls, 'Eye Size', 0.3, 0.7).step(0.1);
  eyes.add(controls, 'Pupil Size', 0.2, 0.3).step(0.01);
  eyes.add(controls, 'Pupil Shape', -0.1, 0.1).step(0.01);

  let deb = gui.addFolder("Debug");

  //gui.add(controls, 'Shaded');
  deb.add(controls, 'Shadows');
  deb.add(controls, 'Show Normals');
  deb.add(controls, 'Colored');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 15), vec3.fromValues(0, 0, 0));
  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(225/255, 240/255, 246/255, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);


  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/static-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/static-frag.glsl')),
  ]);

  const sdf = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/sdf-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sdf-frag.glsl')),
  ]);

  let time = 0.0;
  // This function will be called every frame
  function tick() {

    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

  

    time += 1;
    background.setTime(time);
    sdf.setTime(time);

    sdf.setBodyColors(getBodyColors());
    sdf.setBodySizes(getBodySizes());
    sdf.setResolution(vec3.fromValues(window.innerWidth, window.innerHeight,1));
    sdf.setCamPos(camera.controls.eye);
    sdf.setColored(getFlags());

    renderer.render(camera, sdf, [
      square,
    ],undefined, true);
 


    let ts = 0.01;


    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
