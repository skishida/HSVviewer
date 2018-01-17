import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;
import java.awt.Color;
import java.util.Date;

int pshow = 0;
static int pnum = 0;
static PImage imgRGB;
static int pixX, pixY;
static float imgHSB[][][];
static float histo[][][];
static float histoLog[][][];

boolean hisomode, bgmode, clip;

static String PATH = "";
static String[] filenames;

PeasyCam cam;
PGraphics logWindow;
PFont logFont;
color colorUnderMouse;

void setup() {
  size(1280, 720, P3D);
  frameRate(60);
  smooth();
  logWindow = createGraphics(width, 120);
  logFont = createFont("Consolas",20,true);
  textFont(logFont);
  logWindow.beginDraw();
  logWindow.textFont(logFont);
  logWindow.endDraw();
  
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(0);
  cam.setMaximumDistance(500);

  // get all filename in a directory
  PATH = sketchPath() + "/img";
  filenames = listFileNames(PATH);
  printArray(filenames); //<>//
  pnum = filenames.length; //<>//
  if(pnum==0) {
    println("ERROR: no image file found.");
    exit();
  }else{
    loadImg(); //<>// //<>//
  }
}

void draw() {
  String title = String.format("[frame %d] [fps %6.2f]", frameCount, frameRate);
  surface.setTitle(title);
  
  colorMode(RGB, 255);
  if(bgmode) {
    background(0);
  }else{
    background(255);
  }
  
  fill(255, 0, 0);
  stroke(255);
  strokeWeight(1);
  
  // draw axis
  line(-10, 0, 0, 10, 0, 0);
  line(0, -10, 0, 0, 10, 0);
  line(0, 0, -10, 0, 0, 10);
  float bn=0.0, area=0.0;
  int bnX =0 , bnY = 0;
  
  pushMatrix();
  float h,s,b;
  colorMode(HSB, 360, 100, 100);
  for (int x=0; x<pixX; x++) {
    for (int y=0; y<pixY; y++) {
      //long start = System.nanoTime();
      h = imgHSB[x][y][0];
      s = imgHSB[x][y][1];
      b = imgHSB[x][y][2];
      
      float size = 20;
      if(hisomode) {
        size = histoLog[(int)h][(int)s][(int)b]*20;
      }
      strokeWeight(size);
      
      stroke(h,s,b);
      float i,j,k;
      k = b -50;
      i = s * cos(radians(h));
      j = s * sin(radians(h));
      
      //long astart = System.nanoTime();
      if(clip) {
        if(h == 0.0 && s == 0.0 && b == 0.0){
          
        }else{
          //point(i, j, k);
          beginShape(POINTS); // 遅い
          vertex(i, j, k);
          endShape();
        }
      }else{
        //point(i, j, k);
        line(i,j,k, i,j,k+2);
      }
      //long aend = System.nanoTime();
      
      //long end = System.nanoTime();
      //if( bn < (end - start) / 1000000f) {
      //  bn = (end - start) / 1000000f;
      //  bnX = x;
      //  bnY = y;
      //  area = (aend - astart) / 1000000f;
      //}
    }
  }
  if(bn>2)  System.out.println("Time:" + bn + "ms, areaOut="+ (bn-area) +"ms, x,y = " + bnX + ","+ bnY+ " HSB=" + imgHSB[bnX][bnY][0] + "," + imgHSB[bnX][bnY][1] +"," + imgHSB[bnX][bnY][2] );
  popMatrix();
  
  // UI
  cam.beginHUD();
  colorMode(RGB);
    logWindow.beginDraw();
    logWindow.colorMode(RGB,255);
    logWindow.background(255,200);
    logWindow.noStroke();
    logWindow.image(imgRGB, 10, 10);
    logWindow.text(filenames[pshow], 10, 150);
    
    logWindow.fill(0);
    logWindow.text( "Hue: " + (int)hue(colorUnderMouse)+"\nSat: "+ (int)saturation(colorUnderMouse)+"\nBri: "+ (int)brightness(colorUnderMouse),230,30);
    
    logWindow.colorMode(HSB);
    logWindow.fill(colorUnderMouse);
    logWindow.rect(120, 10, 100, 100);
    logWindow.endDraw();
    
    image(logWindow, 0, height - 120);
  cam.endHUD();
}

void loadImg() {
  colorMode(RGB, 255);
  // load image
    println("Loading :"+filenames[pshow]);
    imgRGB = null;
    imgRGB = loadImage(PATH + "/" + filenames[pshow]);
    imgRGB.resize(100, 100);
    imgRGB.loadPixels();
    pixX = imgRGB.pixelWidth;
    pixY = imgRGB.pixelHeight;
    imgHSB = new float[pixX][pixY][3];
    histo = new float[360][100][100];
    histoLog = new float[360][100][100];
  
  // create HSB matrix
  for (int x=0; x<pixX; x++) {
    for (int y=0; y<pixY; y++) {
      color pix = imgRGB.pixels[x*pixX + y];
      imgHSB[x][y] = Color.RGBtoHSB( (int)red(pix), (int)green(pix), (int)blue(pix), null);
      imgHSB[x][y][0] *= 359;
      imgHSB[x][y][1] *= 99;
      imgHSB[x][y][2] *= 99;
    }
  }
  
  // make 3D histogram
  for (int x=0; x<pixX; x++) {
    for (int y=0; y<pixY; y++) {
      int h = (int)imgHSB[x][y][0];
      int s = (int)imgHSB[x][y][1];
      int b = (int)imgHSB[x][y][2];
      histo[h][s][b] += 1;
    }
    println();
  }
  
  // make logarythm hisogram
  for (int x=0; x<pixX; x++) {
    for (int y=0; y<pixY; y++) {
      int h,s,b;
      h = (int)imgHSB[x][y][0];
      s = (int)imgHSB[x][y][1];
      b = (int)imgHSB[x][y][2];
      histoLog[h][s][b] = log(histo[h][s][b]/3. +1);
    }
  }
  
}


void mouseClicked() {
      colorUnderMouse = get(mouseX, mouseY);
}

void keyPressed() {
  switch(key) {
      case 'q':
        hisomode ^= true;
        break;
      case 'e':
        bgmode ^= true;
        break;
      case 'c':
        clip ^= true;
        break;
      case 'a':
        pshow--;
        if(pshow<0) pshow += pnum;
        loadImg();
        break;
      case 'd':
        pshow++;
        pshow %= pnum;
        loadImg();
        break;
      default:
        break;
  }

  if(key == CODED) {
    if(keyCode == LEFT) {
    }else if(keyCode == RIGHT) {
    }
  }
}