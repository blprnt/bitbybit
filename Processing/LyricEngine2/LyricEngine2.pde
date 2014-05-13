import rita.render.*;
import rita.json.*;
import rita.support.*;
import rita.*;

HashMap<String, String> stopList = new HashMap();
String doc;
String[] sentences;
String[] posArray;
String[] stressArray;
String[] countArray;

float tol = 0.3;

ArrayList<String> out = new ArrayList();

String dataPath = "../../data/";
String dl = "|~~|";

String currentText = "";
float cursorPos = 0;

float xoff = 0;
float txoff = 0;

int keyCount = 0;
int keyTarget = 60;

PFont labelText;

void setup() {
  size(1280, 720);
  
  labelText = createFont("Helvetica",36);
  textFont(labelText);

  String[] files = {
    //"bible", "shakes", "mobydick", "greygardens", "bieber"
    "freud"
  };
  //makeStopList(dataPath + "stop.txt");
  
  for (String s:files) {
    processCorpus(s);
  }
  
  for (String s:files) {
    loadCorpus(s);
    convertLyrics(s, "inthena.txt");
  }
  
  
  loadCorpus("bible");
}

void processCorpus(String url) {
  //Make word count doc
  IntDict wc = doWordCount(dataPath + url + ".txt");

  //Fetch the unprocessed corpus
  String[] rows = loadStrings(dataPath + url + ".txt");
  //Make the outgoing array


  String[] out = new String[rows.length];
  for (int i = 0; i < rows.length; i++) {
    //println(i);
    String row = rows[i];
    //Parts of Speech
    String pos = join(RiTa.getPosTags(row), " ");
    //Stresses
    String stress = "";
    try {
      stress = RiTa.getStresses(row);
    } 
    catch (Exception e) {
      println("FAILED on " + row);
    }
    //Word counts
    String[] words = RiTa.tokenize(row);
    String[] counts = new String[words.length];
    for (int j = 0; j < words.length; j++) {
      int c = wc.get(RiTa.stripPunctuation(words[j]).toLowerCase()); 
      counts[j] = str(c);
    }
    String countList = join(counts, " ");

    out[i] = row + dl + pos + dl + stress + dl + countList;
  }


  //Save
  saveStrings(dataPath + url + "_processed.txt", out);
}

void loadCorpus(String url) {
  String[] rows = loadStrings(dataPath + url + "_processed.txt");
  sentences = new String[rows.length];
  posArray = new String[rows.length];
  stressArray = new String[rows.length];
  countArray = new String[rows.length];

  for (int i = 0; i < rows.length; i++) {
    String row = rows[i];
    String[] cols = split(row, dl);
    sentences[i] = cols[0];
    posArray[i] = cols[1];
    stressArray[i] = cols[2];
    countArray[i] = cols[3];
  };
}

void pickText() {
 println(getPosMatch(currentText)); 
}


void draw() {
  
  xoff = lerp(xoff, txoff, 0.1);
  background(0);
  textSize(36);
  int c = 0;
  translate(width/2 + xoff,height/2);
  text(currentText,0,30);
  cursorPos = textWidth(currentText);
  translate(cursorPos + 5,0);
  rect(0,0,5,36);
  
  txoff = -cursorPos * 0.5;
  
  if (keyCount < keyTarget) {
   keyCount ++;
   if (keyCount == keyTarget && currentText.length() > 0 ) pickText(); 
  }
  
}

void convertLyrics(String token, String url) {
  String[] original = loadStrings(dataPath + url);
  String[] newsong = new String[original.length];
  for (int i = 0; i < original.length; i++) {
    String n1 = getPosMatch(original[i]);
    String n2 = getPosMatch(original[i]);
    String n3 = getPosMatch(original[i]);
    newsong[i] = (n1.length() == 0) ? original[i]:(n1 + "/" + n2 + "/" + n3);
  }
  saveStrings(dataPath + token + "_" + url, newsong);
}

void makeStopList(String url) {
  String[] rows = loadStrings(url);
  for (String s:rows) {
    stopList.put(s, s);
  }
}

boolean checkStop(String w) {
  return(!stopList.containsKey(w));
}

String getPosMatch(String pos) {

  //Get the Pos string
  String[] matchList = RiTa.getPosTags(pos);
  String match = join(matchList, " ");
  String stress = RiTa.getStresses(pos);
  
  int syllables = 0;
  String[] sswords = pos.split(" ");
  for (String w:sswords) {
    syllables += w.split("/").length;
  }

  boolean isQ = RiTa.isQuestion(pos);

  //Find candidate string that match the POS somewhere
  ArrayList<String[]> candidates = new ArrayList();

  for (int i = 0; i < sentences.length; i++) {
    String s = sentences[i];
    String p = posArray[i];
    if (p.indexOf(match) != -1) {
      String[] sa = {
        s, p, stressArray[i], countArray[i]
      };
      candidates.add(sa);
    }
  }

  //Get the pieces
  ArrayList<String> returnSegments = new ArrayList();
  for (String[] s:candidates) {
    String ss = RiTa.stripPunctuation(s[0]);
    String[] words = RiTa.tokenize(s[0]);
    String[] spos = s[1].split(" ");
    String[] stressa = s[2].split(" ");
    String[] counta = s[3].split(" ");

    for (int i = 0; i < words.length - matchList.length + 1; i++) {
      String sss = join(java.util.Arrays.copyOfRange(spos, i, i + matchList.length), " ");

      int posdist = computeEditDistance(sss, match);
      float posfdist = (float) posdist / sss.length();

      if (posfdist < tol && stressa.length >= words.length) {

        String seg = join(java.util.Arrays.copyOfRange(words, i, i + matchList.length), " ");

        String sstress = join(java.util.Arrays.copyOfRange(stressa, i, i + matchList.length), " ");
        boolean sisQ = RiTa.isQuestion(s[0]);
        
        String scounts = join(java.util.Arrays.copyOfRange(counta, i, i + matchList.length), " ");
        String[] clist = scounts.split(" ");
        int scoreCount = 0;
        for (String c:clist) {
          scoreCount += int(c);
        }

        int ssyllables = 0;
        String[] swords = seg.split(" ");
        for (String w:swords) {
          ssyllables += w.split("/").length;
        }

        int dist = computeEditDistance(stress, sstress);
        float stol = (float) dist/stress.length();

        if ((stol < tol || stress.length() == sstress.length())) {
          for (int k = 0; k < sqrt(scoreCount); k++) returnSegments.add(seg);
        }
      };
    }
  }
  String rs = "";
  if (returnSegments.size() > 0) rs = returnSegments.get(floor(random(returnSegments.size())));
  return(rs);
}

void makePosList(String url, String pos) {


  //Get the Pos string
  String match = join(RiTa.getPosTags(pos), " ");

  //Make a print writer
  PrintWriter writer = createWriter(match + ".txt");

  for (String s:sentences) {
    if (join(RiTa.getPosTags(s), " ").indexOf(match) != -1) writer.println(RiTa.stripPunctuation(s));
  }

  writer.flush();
  writer.close();
}



IntDict doWordCount(String url) {

  //This is a counter for the words
  IntDict counter = new IntDict();

  String[] rows = loadStrings(url);
  String doc = join(rows, " ");
  //Split into sentences using RiTa
  String[] sentences = RiTa.splitSentences(doc);
  //Split each sentence into words
  for (String s:sentences) {
    String[] words = RiTa.tokenize(RiTa.stripPunctuation(s));
    for (String w:words) {
      if (checkStop(w.toLowerCase())) counter.add(w.toLowerCase(), 1);
    }
  }

  /*
  //Make a print writer
   PrintWriter writer = createWriter("count.txt");
   
   counter.sortValuesReverse();
   int c = 0;
   for (String k:counter.keys()) {
   if (c < 100) println(k + ":" + counter.get(k)); 
   writer.println(k + "," + counter.get(k));
   c++;
   }
   
   
   writer.flush();
   writer.close();
   
   */

  return(counter);
}

int computeEditDistance(String s1, String s2) {
  s1 = s1.toLowerCase();
  s2 = s2.toLowerCase();

  int[] costs = new int[s2.length() + 1];
  for (int i = 0; i <= s1.length(); i++) {
    int lastValue = i;
    for (int j = 0; j <= s2.length(); j++) {
      if (i == 0)
        costs[j] = j;
      else {
        if (j > 0) {
          int newValue = costs[j - 1];
          if (s1.charAt(i - 1) != s2.charAt(j - 1))
            newValue = Math.min(Math.min(newValue, lastValue), 
            costs[j]) + 1;
          costs[j - 1] = lastValue;
          lastValue = newValue;
        }
      }
    }
    if (i > 0)
      costs[s2.length()] = lastValue;
  }
  return costs[s2.length()];
}

void keyPressed() {
  keyCount = 0;
 if (keyCode == 8) {
   if (currentText.length() > 0) currentText = currentText.substring(0,currentText.length() - 1);
 } else {
   currentText += key;
 }
}

