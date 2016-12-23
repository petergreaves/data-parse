package com.easyjet.fcp.test.io;

import java.io.BufferedReader;
import java.io.Closeable;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import com.easyjet.fcp.test.util.IDataFileReader;

public class DataFileReader implements IDataFileReader{
	
	private static final Logger logger = Logger.getRootLogger();
	
	 private File file;

	    public List<String> readFile() {
	        List<String> list = new ArrayList<String>();
	        BufferedReader reader = null;
	        try {
	            reader = new BufferedReader(new FileReader(getFile()));
	            String line = null;
	            while ((line = reader.readLine()) != null){
	            	
	            	list.add(line);
	            }
	        } catch (IOException e) {
	            logger.error(e.getMessage());
	        } finally {
	            closeQuietly(reader);
	        }
	        return list;
	    }

	    private void closeQuietly(Closeable c) {
	        if (c != null) {
	            try {
	                c.close();
	            } catch (IOException ignored) {}
	        }
	    }

	    public File getFile() {
	        return file;
	    }

	    public void setFile(File file) {
	        this.file = file;
	    }

}
