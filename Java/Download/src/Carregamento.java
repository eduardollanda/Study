
public class Carregamento extends Thread {
	
	
	public Carregamento() {
		start();
	}
	public void run () {
		int max = 100;
		int i = 1;
		int e = 0;
		while (i <= max ) {
			System.out.println("");
			i++;
			e = 0;
			try {
				Thread.sleep(250);
			} catch (InterruptedException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
			while (e <= i) {
				System.out.print("=");
				e++;
			}
		}
	}
}
