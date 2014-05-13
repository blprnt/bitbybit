import rita.render.*;
import rita.json.*;
import rita.support.*;
import rita.*;

HashMap<String, String> stopList = new HashMap();
String doc;
String[] sentences;

float tol = 0.3;

ArrayList<String> out = new ArrayList();

void setup() {
  size(1280, 720);
  makeStopList("../../data/stop.txt");
  loadCorpus("../../data/bieber.txt");

  convertLyrics("inthena.txt");

}

void draw() {
  background(0);
  textSize(36);
  int c = 0;
  for (String s:out) {
    text(s, 50, 50 + (c * 40));
    c++;
  }
}

void convertLyrics(String url) {
  String[] original = loadStrings(url);
  String[] newsong = new String[original.length];
  for (int i = 0; i < original.length; i++) {
   String n = getPosMatch(original[i]);
   newsong[i] = (n.length() == 0) ? original[i]:n; 
  }
  saveStrings("new_" + url, newsong);
}

void loadCorpus(String url) {
  String[] rows = loadStrings(url);
  String doc = join(rows, " ");
  //Split into sentences using RiTa
  sentences = RiTa.splitSentences(doc);
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
  String stress = RiTa.getStresses(RiTa.stripPunctuation(pos));

  int syllables = 0;
  String[] sswords = pos.split(" ");
  for (String w:sswords) {
    syllables += w.split("/").length;
  }

  boolean isQ = RiTa.isQuestion(pos);

  //Find candidate string that match the POS somewhere
  ArrayList<String> candidates = new ArrayList();
  println(pos);
  println(match);

  for (String s:sentences) {
    if (join(RiTa.getPosTags(s), " ").indexOf(match) != -1) {
      candidates.add(s);
    }
  }

  //Get the pieces
  ArrayList<String> returnSegments = new ArrayList();
  for (String s:candidates) {
    String ss = RiTa.stripPunctuation(s);
    String[] words = RiTa.tokenize(ss);
    String[] spos = RiTa.getPosTags(ss);

    for (int i = 0; i < words.length - matchList.length + 1; i++) {
      String sss = join(java.util.Arrays.copyOfRange(spos, i, i + matchList.length), " ");
      
      int posdist = computeEditDistance(sss, match);
      float posfdist = (float) posdist / sss.length();

      if (posfdist < tol) {

        String seg = join(java.util.Arrays.copyOfRange(words, i, i + matchList.length), " ");

        try {
          String sstress = RiTa.getStresses(seg);
          boolean sisQ = RiTa.isQuestion(s);

          int ssyllables = 0;
          String[] swords = seg.split(" ");
          for (String w:swords) {
            ssyllables += w.split("/").length;
          }

          int dist = computeEditDistance(stress, sstress);
          float stol = (float) dist/stress.length();

          if (pos.equals("incomplete")) {
            println("VV");
            println(pos);
            println(stress);
            println(seg);
            println(sstress);
          }

          if ((stol < tol || stress.length() == sstress.length())) {
            returnSegments.add(seg);
          }
        } 
        catch (Exception e) {
          println("failed on " + seg);
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

void makeQuestionList(String url) {
  String[] rows = loadStrings(url);
  String doc = join(rows, " ");
  //Split into sentences using RiTa
  String[] sentences = RiTa.splitSentences(doc);

  //Make a print writer
  PrintWriter writer = createWriter("questions.txt");

  for (String s:sentences) {
    if (RiTa.isW_Question(s) && s.indexOf("?") != -1) writer.println(s);
  }

  writer.flush();
  writer.close();
}

void makeStressList(String url, String stress) {
  String[] rows = loadStrings(url);
  String doc = join(rows, " ");
  //Split into sentences using RiTa
  String[] sentences = RiTa.splitSentences(doc);

  //Get the Pos string
  String match = RiTa.getStresses(stress);

  //Make a print writer
  PrintWriter writer = createWriter(stress + ".txt");

  for (String s:sentences) {
    String[] words = RiTa.tokenize(s);
    for (String w:words) {
      try {
        if (RiTa.getStresses(w).equals(match)) writer.println(w);
      } 
      catch(Exception e) {
      }
    }
  }

  writer.flush();
  writer.close();
}


void makeSentenceList(String url, String w) {
  String[] rows = loadStrings(url);
  String doc = join(rows, " ");
  //Split into sentences using RiTa
  String[] sentences = RiTa.splitSentences(doc);

  //Make a print writer
  PrintWriter writer = createWriter(w + ".txt");

  for (String s:sentences) {
    if (s.toLowerCase().indexOf(w) != -1) writer.println(RiTa.stripPunctuation(s));
  }

  writer.flush();
  writer.close();
}

void doWordCount(String url) {

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

