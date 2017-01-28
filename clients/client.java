import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

public class client {

  public static void main(String[] args) throws Exception {

    if (args.length != 1) {
      System.err.println("Usage:");
      System.exit(1);
    }

    if (!args[0].equals("ga") && !args[0].equals("gd") && !args[0].equals("gv")) {
      System.err.println("Usage:");
      System.exit(1);
    }

    String stdInLine;
    String slurp = "";
    BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
    while ((stdInLine = stdIn.readLine()) != null) {
      slurp += stdInLine;
    }

    String urlParameters = "foinse=" + URLEncoder.encode(args[0],"UTF-8") + "&teacs=" + URLEncoder.encode(slurp, "UTF-8");
    byte[] postData = urlParameters.getBytes("UTF-8");

    String url = "http://borel.slu.edu/cgi-bin/seirbhis3.cgi";
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
    if (responseCode != 200) {
      System.err.println("HTTP Error code " + Integer.toString(responseCode));
      System.exit(1);
    }

    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
    String inputLine;
    StringBuffer response = new StringBuffer();

    while ((inputLine = in.readLine()) != null) {
      response.append(inputLine);
    }
    in.close();

    String resp = response.toString();
// parse resp as JSON

// verify it parses correctly
// varify it gives an array!

// loop over the array, pick out source/target from each and print em

    System.out.println(resp);
  }

}
