package com.easyjet.fcp.test.io;

import java.util.List;

import com.easyjet.fcp.test.domain.FlightSchedule;

public interface IScheduleWriter {

	String getPath();
	void setPath(String path);
	void write(List<FlightSchedule> s);
}
