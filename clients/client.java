import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

public class client {

  public static void fatalError(String msg) {
      System.err.println(msg);
      System.exit(1);
  }

  // when called, index i points to first char *after* opening double quote
  // return the index of the first char *after* closing double quote
  public static int substringOutput(String json, int i) {
    StringBuilder sb = new StringBuilder();
    int len = json.length();
    int j = i;
    while (j < len && json.charAt(j) != '"') {
      if (json.charAt(j)=='\\') j++;
      sb.append(json.charAt(j));
      j++;
    }
    if (j >= len) fatalError("Malformed JSON.");
    System.out.print(sb.toString());
    return j+1;
  }

  // a real client should use an actual JSON parser;
  // doing it this way for the sake of a dependency-free client
  public static void jsonToOutput(String json) {
    int len = json.length();
    int i=0;
    while (i < len && Character.isWhitespace(json.charAt(i))) i++;
    if (i==len || json.charAt(i)!='[') fatalError("Malformed JSON.");
    i++;
    while (i < len && Character.isWhitespace(json.charAt(i))) i++;
    while (i < len && json.charAt(i)=='[') {
      i++;
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
      if (i==len || json.charAt(i)!='"') fatalError("Malformed JSON.");
      i++;
      i = substringOutput(json,i);
      System.out.print(" => ");
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
      if (i==len || json.charAt(i)!=',') fatalError("Malformed JSON.");
      i++;
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
      if (i==len || json.charAt(i)!='"') fatalError("Malformed JSON.");
      i++;
      i = substringOutput(json,i);
      System.out.print("\n");
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
      if (i==len || json.charAt(i)!=']') fatalError("Malformed JSON.");
      i++;
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
      if (i < len && json.charAt(i)==']') break;
      if (i==len || json.charAt(i)!=',') fatalError("Malformed JSON.");
      i++; 
      while (i < len && Character.isWhitespace(json.charAt(i))) i++;
    }
  }

  public static void main(String[] args) throws Exception {

    if (args.length != 1)
      fatalError("Usage: java client [ga|gd|gv]");

    if (!args[0].equals("ga") && !args[0].equals("gd") && !args[0].equals("gv"))
      fatalError("Usage: java client [ga|gd|gv]");

    String stdInLine;
    StringBuffer slurp = new StringBuffer();
    BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
    while ((stdInLine = stdIn.readLine()) != null) {
      slurp.append(stdInLine);
      // maybe a pain if stdin doesn't end in a newline
      slurp.append("\n");
    }

    String urlParameters = "foinse=" + URLEncoder.encode(args[0],"UTF-8") + "&teacs=" + URLEncoder.encode(slurp.toString(), "UTF-8");
    byte[] postData = urlParameters.getBytes("UTF-8");

    String url = "https://cadhan.com/api/intergaelic/3.0";
    URL obj = new URL(url);
    HttpURLConnection conn = (HttpURLConnection) obj.openConnection();
    conn.setDoOutput(true);
    conn.setRequestMethod("POST");
    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    conn.setRequestProperty("charset", "utf-8");
    conn.setRequestProperty("Content-Length", Integer.toString(postData.length));

    DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
    wr.write(postData);
    wr.flush();
    wr.close();

    int responseCode = conn.getResponseCode();
    if (responseCode != 200)
      fatalError("HTTP Error code " + Integer.toString(responseCode));

    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
    String inputLine;
    StringBuffer response = new StringBuffer();
    while ((inputLine = in.readLine()) != null) {
      response.append(inputLine);
    }
    in.close();

    jsonToOutput(response.toString());
  }

}
