import rita.*;

RiMarkov markov;
String[] lines = {"press the mouse!"};

void setup() {
 size(1280,720,P3D);
 
 markov = new RiMarkov(3);  
 markov.loadFile("/Users/jerthorp/code/bitbybit/data/greygardens.txt");
 markov.loadFile("/Users/jerthorp/code/bitbybit/data/songs.txt");
}

void draw() {
  background(0);
  textSize(24);
  text(lines[0], 50, 250,600,300);
}

void mousePressed() {
 lines = markov.generateSentences(1); 
 println(lines[0]);
}


