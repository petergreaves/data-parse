package com.easyjet.fcp.test.util;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class FareMap implements java.util.Map<String, String>{

	private Map<String, String> map;
	
	public static final String AU_KEY = "AU";
	public static final String FARE_CLASS_CODE_KEY = "FareClassCode";
	public static final String CURRENCY_CODE_KEY = "CurrencyCode";
	public static final String EXTENDED_PRICE_KEY = "ExtendedPrice";
	public static final String FLIGHT_KEY_KEY = "FlightKey";
	public static final String SPECIAL_FARE_DESC_KEY = "SpecialFareCodeDesc";
	public static final String AUMIN_KEY = "AUmin";
	public static final String SEATS_SOLD_KEY = "SeatsSold";
	
	
	private final String[] keys = {FARE_CLASS_CODE_KEY,CURRENCY_CODE_KEY,EXTENDED_PRICE_KEY,
								   FLIGHT_KEY_KEY,
								   SPECIAL_FARE_DESC_KEY,AUMIN_KEY,
								   AU_KEY,SEATS_SOLD_KEY};
			

	public FareMap(String[] ar){
		
	
		for (int k=0;k<ar.length;k++){
			
			put(keys[k], ar[k]);
		}
		
	}
	
	@Override
	public String toString() {
		return "FareMap [map=" + map + "]";
	}
	
	

	public String put(String key, String value){
		
		if (null == map){
			map = new HashMap<String,String>();
			
		}
		
		
		String prev = map.get(key);
		// replace single quotes
		
		value = value.replaceAll("'", "\"");
				
		if (key.equals("FareClassCode")){
			
			
			int k = value.indexOf("\"");
			String at = value.substring(k);
			value = at;
		
		}
		
		
		
		// replace single quotes
		
		
		
		value = value.replaceAll("'", "\"");
		
		map.put(key,  value.trim());
		
		return prev;
	}
	
	public String get(String key){
		
		return map.get(key);
	}

	@Override
	public int size() {
		// TODO Auto-generated method stub
		return map.size();
	}

	@Override
	public boolean isEmpty() {
		// TODO Auto-generated method stub
		return map.isEmpty();
	}

	@Override
	public boolean containsKey(Object key) {
		// TODO Auto-generated method stub
		return map.containsKey(key);
	}

	@Override
	public boolean containsValue(Object value) {
		// TODO Auto-generated method stub
		return map.containsValue(value);
	}

	@Override
	public String get(Object key) {
		// TODO Auto-generated method stub
		return map.get(key);
	}

	@Override
	public String remove(Object key) {
		// TODO Auto-generated method stub
		return map.remove(key);
	}

	@Override
	public void putAll(Map<? extends String, ? extends String> m) {
		
		map.putAll(m);
		
	}

	@Override
	public void clear() {
		map.clear();
		
	}

	@Override
	public Set<String> keySet() {
		// TODO Auto-generated method stub
		return map.keySet();
	}

	@Override
	public Collection<String> values() {
		// TODO Auto-generated method stub
		return map.values();
	}

	@Override
	public Set<java.util.Map.Entry<String, String>> entrySet() {
		// TODO Auto-generated method stub
		return map.entrySet();
	}
	



}
