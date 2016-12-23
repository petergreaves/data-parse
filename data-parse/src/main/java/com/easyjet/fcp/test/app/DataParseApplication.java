package com.easyjet.fcp.test.app;

import java.util.List;

import org.apache.log4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import com.easyjet.fcp.test.domain.FlightSchedule;
import com.easyjet.fcp.test.io.DataFileReader;
import com.easyjet.fcp.test.io.IScheduleWriter;
import com.easyjet.fcp.test.util.IDataFileReader;
import com.easyjet.fcp.test.util.IDataParser;

@SpringBootApplication
public class DataParseApplication {

	private static final Logger logger = Logger.getRootLogger();

	public static void main(String[] args) {
		
		SpringApplication.run(DataParseApplication.class, args);
		
		try (ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("beans.xml");) {

			IDataParser parser = (IDataParser) context.getBean("parser");
			IDataFileReader dfr = (IDataFileReader) context.getBean("dfr");
			
			String fileIn = ((DataFileReader)context.getBean("dfr")).getFile().getAbsolutePath();
			logger.info("Parsing input file : " + fileIn);
		
			// read the file from the location specified in application.properties
			List<String> list = dfr.readFile();

			for (String s : list) {
				parser.dispatch(s);	// pass the line from the file to the parser
			}

			// get the list of schedules from the parser
			List<FlightSchedule> schedules = parser.getFlightSchedules();
			logger.info("Schedules : " + schedules.size());

			
			// write to file specified in application.properties

			String fileOut = ((IScheduleWriter)context.getBean("sw")).getPath();
			logger.info("Writing output file : " + fileOut);
			IScheduleWriter sw = (IScheduleWriter) context.getBean("sw");
			sw.write(schedules);

			// close the context
		} catch (Exception e) {
			
			logger.error(e.getMessage());
		}

	}

}
