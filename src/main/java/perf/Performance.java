package main.java.perf;
import main.java.veracity.*;

public class Performance {
	
	public String workload;
	public String schema;
	public float execution_time;
	public ResultsetVeracity veracity;
	
	public Performance(String workload, String schema, float execution_time, ResultsetVeracity veracity) {
		super();
		this.workload = workload;
		this.schema = schema;
		this.execution_time = execution_time;
		this.veracity = veracity;
	}

	@Override
	public String toString() {
		return "Performance [workload=" + workload + ", schema=" + schema + ", execution_time=" + execution_time
				+ ", veracity=" + veracity + "]";
	}
	public String toCSV() {
		if (veracity != null) return workload + "," + schema + "," + execution_time + "," + veracity.toCSV();
		else return workload + "," + schema + "," + execution_time + ",n/a" ;
	}
	
}
