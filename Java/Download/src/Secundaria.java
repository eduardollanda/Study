
public class Secundaria extends Thread {
	
	
	public Secundaria() {
		start();
	}
	
	public void run () {
		Download();
	}
	public int Download() {
		int porcento = 0;
		for (porcento = 0 ; porcento <= 100 ; porcento++) {
			try {
				Thread.sleep(250);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		System.out.println("\nCarregamento completo");
		return porcento;
	}
}
