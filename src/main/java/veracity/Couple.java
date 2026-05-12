package main.java.veracity;

public class Couple {
	public String column_name;
	public Object column_value;
	
	
	public Couple(String column_name, Object column_value) {
		super();
		this.column_name = column_name;
		this.column_value = column_value;
	}


	@Override
	public String toString() {
		return "Couple [column_name=" + column_name + ", column_value=" + column_value + "]";
	}
	
}
