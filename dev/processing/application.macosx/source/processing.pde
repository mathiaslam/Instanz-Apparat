import de.bezier.data.sql.*;
import java.util.Date;
import java.util.Calendar;
import processing.serial.*;

Serial myPort;  
MySQL msql;
String typing = "";
PrintWriter output;
PFont font;
String typedText = "";
Timer refresh;
StringList blacklist;

void setup()
{
  size(displayWidth, displayHeight);
  font = loadFont("Monaco-10.vlw");

  println(Serial.list());
  String portName = Serial.list()[8];
  myPort = new Serial(this, portName, 9600);

  refresh = new Timer(1000);
  refresh.start();	

  String user     = "root";
  String pass     = "root";

  String database = "Bachelorprojekt";

  msql = new MySQL( this, "localhost:8889", database, user, pass );
  msql.connect();
  myPort.write("LBTyping");
  blacklist = new StringList();
}

void draw()
{
  background(229);
  stroke(0);
  strokeWeight(2);
  fill(229);
  rect(20, 20, 1400, 860);
  noStroke();
  fill(0);
  rect(23, 23, 1395, 855);

  textFont(font, 10);
  fill(255);
  text(typedText+(frameCount/10 % 2 == 0 ? "_" : ""), 45, 860);
  printWord();
  showTopBlackwords();
  lastWords();
}

void keyReleased() {
  if (key != CODED) {
    switch(key) {
    case BACKSPACE:
      typedText = typedText.substring(0, max(0, typedText.length()-1));
      break;

    case ENTER:
    case RETURN:

      saveWord();
      typedText = "";

      break;
    case ESC:
    case DELETE:
      break;
    default:
      typedText += key;
    }
  }
}

void printWord() {   
  if (refresh.isFinished()) {      
    msql.query( "SELECT word FROM `term` WHERE (level_id = 3 OR level_id = 4 ) ORDER BY RAND() LIMIT 1" );
    msql.next();
    //println( "number of rows: " + msql.getString(1) );
    String foundWord = msql.getString(1);
    //String foundWord = "Hosenkacker";
    int foundWordLength = foundWord.length();
    msql.query("SELECT word FROM `blacklist` WHERE word = '"+foundWord+"' AND hidden_until > DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 HOUR)");

    int blacklistSize = blacklist.size();
    if (blacklistSize > 10) {
      blacklist.remove(0);
      blacklist.append(foundWord);
    } 
    else {
      blacklist.append(foundWord);
    }
    
    println(blacklist);
    
    if (msql.next()) {
      println( "number of rows ####: " + foundWord );
      myPort.write(foundWord);
      for (int i=0; i < foundWordLength; i++) {         
        myPort.write(TAB);
        myPort.write(TAB);
        myPort.write("#");
        myPort.write(TAB);
        myPort.write(TAB);
      }
      myPort.write("ä");
      myPort.write(TAB);
      myPort.write(TAB);
      myPort.write(RETURN);
    } 
    else {
      println( "number of rows: " + foundWord );
      myPort.write(foundWord);
      myPort.write("ä");
      myPort.write(TAB);
      myPort.write(TAB);
      myPort.write(RETURN);
    }
    refresh.start();
  }
}



void saveWord() {
  msql.query("SELECT word FROM `blacklist` WHERE word = '"+typedText+"'");
  if (msql.next()) {
    msql.query("UPDATE blacklist SET count = count + 1 WHERE word = '"+typedText+"'");
  } 
  else {  
    Calendar calendar = Calendar.getInstance();
    calendar.add(Calendar.HOUR, 6);
    Date dt = calendar.getTime();

    java.text.SimpleDateFormat sdf = 
      new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    String currentTime = sdf.format(dt);

    println(currentTime);

    msql.query("INSERT INTO `Bachelorprojekt`.`blacklist` (`word`, `count`, `anticount`, `hidden_until`) VALUES ('"+typedText+"', '1', '0', '"+currentTime+"');");
  }
}

void showTopBlackwords() {
  fill(255);
  text("Last typed Blackwords", 45, 60);
  msql.query("SELECT word FROM blacklist ORDER BY id DESC LIMIT 10");
  int i = 0;
  while (msql.next ()) {
    String word = msql.getString(1);
    text(word, 45, 85+i*20);
    i++;
  }
}

void lastWords() {
  fill(255);
  text("Last words from Database", 200, 60);
  for (int i=0; i<blacklist.size(); i++) {
    String blackword = blacklist.get(i);

    text(blackword, 200, 85+i*20);
  }
}

