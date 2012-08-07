public class GW_GWEngageUtilities {


	
	public class debugLogger {
		// debug log wrapper at request of SF security review
		
		private boolean writeDebugs = false;
		
		public debugLogger() {
			// we want to enable debug logging if we're in the DE org, or an unmanaged environment
			// we want it to stay disabled if it's a subscriber instance w/ installed package
			if (InETPackage) {
				if (InETPackageDevOrg) writeDebugs = true;
			} else {
				writeDebugs = true;
			}
		}
		
		public void debug(string msg) {
			if (writeDebugs) system.debug (LoggingLevel.WARN,msg);
		} 
	}




    /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */
    
    // NAMESPACE PREFIX METHODS
    
    public static string addNSPrefixET (string str, boolean isETField, boolean isNP02Field) {
	     if (str.endsWith('__c') || str.endsWith('__r') ) {
	     	if (str.contains('.')) {
	     		// if we're passed a related field w/ object notation, recurse and do each part of the fieldname separately
	     		// that's because if we may need namespace on both the relationship and the fieldname
	     		// for example in npo02 we need npo02__Household__r.npo02__MembershipEndDate__c
	     		string[] strParts = str.split('\\.');	// need to escape the dot char since this is regex
	     		string newString = '';
	     		for (string s : strParts) {
	     			newString += addNSPrefixET(s,isETField,isNP02Field) + '.';
	     		}
	     		newString = newString.substring(0,newString.length()-1);   //lop off trailing period
	     		return newString;
	     	} else {
				if (isETField) {
					// for fields that are part of ET (like the level fields in contact and campaign)
					// possibilities are:
					// * GWE prefix (ET package installed in NPSP context, or ET package dev instance)
					// * GWBase prefix (GWBase installed, or GWBase package dev instance)
					// * no prefix (unmanaged context, e.g. git clone of GWBase)
					if (InETPackage) {
						return 'gwe__' + str;
					} else {
						return GW_Utilities.StrTokenNSPrefix(str);
					}
				} else {
					// OTOH, if the fields is not part of ET, but rather part of either GWBase or NPSP (like opp rollup fields)
					// possibilities are:
					// * np02 or npe01 prefix (NPSP package installed - which prefix depends on which package the field is in)
					// * GWBase prefix (NPSP not installed, GWBase installed or GWBase package dev instance)
					// * no prefix (as above)
					// note that we don't allow for the case of a developer/unmanaged instance of NPSP, since we (GW) never work in that context
					if (IsNPSPHHInstalled) {
						if (isNP02Field) {
							return 'npo02__' + str;
						} else {
							return 'npe01__' + str;
						}
					} else {
						return GW_Utilities.StrTokenNSPrefix(str);
					}
				}
	     	}
	     } else {
		     return str;
	     }
	     
	}
		    
    public static string addAllNSPrefixET (string str,boolean isETFields, boolean isNP02Fields) {
		string[] fields = str.split(',');
		string newString = '';
		for (string s:fields) {
			s = s.trim();
			newString += addNSPrefixET (s,isETFields,isNP02Fields) + ',';
		}
		newString = newString.substring(0,newString.length()-1);   //lop off trailing period
		return newString;
	}
		    
	private static boolean fCheckedForNPSPHH = false;
	public static boolean IsNPSPHHInstalled {
		get {
			if (!fCheckedForNPSPHH) {
				Schema.SObjectType token = Schema.getGlobalDescribe().get('npo02__Household__c');
				IsNPSPHHInstalled = (token != null);
				fCheckedForNPSPHH = true;
			}
			return IsNPSPHHInstalled;
		}
		set;
	}

	// some older versions of the NPSP package don't have the "Best Gift Year" field
	// to avoid errs, don't assume that this field is available until we check for it	
	private static boolean fCheckedForNPSPBestGiftYear = false;
	public static boolean NPSPHasBestGiftYear {
		get {
			if (!fCheckedForNPSPBestGiftYear) {
				Map<String, Schema.SObjectField> M = Schema.SObjectType.Contact.fields.getMap();
				NPSPHasBestGiftYear = (M.keyset().contains('npo02__best_gift_year__c'));
				fCheckedForNPSPBestGiftYear = true;
			}
			return 	NPSPHasBestGiftYear;		
		}
		set;
	}
		    
	private static boolean fCheckedForGWBase = false;
	public static boolean IsGWBaseInstalled {
		get {
			if (!fCheckedForGWBase) {
				Schema.SObjectType token = Schema.getGlobalDescribe().get('ONEN_Household__c');
				IsGWBaseInstalled = (token != null);
				fCheckedForGWBase = true;
			}
			return IsGWBaseInstalled;
		}
		set;
	}
		
	private static boolean CheckedForETPkg = false;
	public static boolean InETPackageDevOrg = false;
	public static boolean InETPackage {
		get {
			if (!CheckedForETPkg) {
				// first try to look up a ET object using ET pkg namespace - if this works, we're either in the package DE org, or in a subscriber org
				// in the package DE org, we can either use the namespace prefixes or not, but there's no harm in using them
				Schema.SObjectType token = Schema.getGlobalDescribe().get('gwe__EngagementTrackerSettings__c');
				if (token != null) {
					InETPackage = true;
					CheckedForETPkg = true;
					// and we furthermore want to know if we're in the package DE
					// if the describe without the prefix works too, then we know that's where we are
					Schema.SObjectType token2 = Schema.getGlobalDescribe().get('EngagementTrackerSettings__c');
					if (token2 != null) InETPackageDevOrg = true;
					//if (UserInfo.getOrganizationId() == ET_DEV_ORG_ID) InETPackageDevOrg = true;
				} else {
					// if this doesn't work, we are in an unmanaged environemnt, such as a cloned developer instance (git clone)
					// here we don't want the namespace prefixes
					// we used to do a query here, but we don't think we need to anymore
					InETPackage = false;
					CheckedForETPkg = true;
					/*
					string soql = 'SELECT Id,gwe__Engagement_Level__c FROM Contact LIMIT 1';
					try {
						SObject[] recs = database.query(soql);
					} catch (exception e) {
						system.debug ('err: ' + e.getMessage() );
						InETPackage = false;
						CheckedForETPkg = true;
					} finally {
						if (!CheckedForETPkg) {
							InETPackage = true;
							CheckedForETPkg = true;
						}
					}
					*/
				}
			}
			return InETPackage;
		}
		set;
	}


    /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */
    
	// methods called from triggers
	
	public static void BlankETConFields (list<Contact> cons) {
		// called from before insert trigger
		// blank out all ET fields on contact on insert
		// this is done to prevent problems when contact is cloned, since some fields are semi-persistent
		// e.g. peak level won't drop once it's set
		// and as long as we're nulling some it's less confusing for user if we null them all
		string fieldList = addAllNSPrefixET(GW_BATCH_EngagementRollup.CON_FIELDS_ET_EDITABLE,true,false);
		string[] fieldnames = fieldList.split(',');
		for (Contact con : cons) {
			for (string fieldname : fieldnames) {
				con.put(fieldname , null);
			}
		}
	}


    // called from the Contact before trigger
    public static void ContactEngagementLvlOverride() {    
        // when engagement lvl override gets set, apply the default time limit unless user has specified otherwise
        
        Contact[] cons = new Contact[0];
        integer months = (GW_BATCH_EngagementRollup.settings.Override_Default_Duration__c==null) ? GW_BATCH_EngagementRollup.settings.Timeframe_Recent__c.intvalue() : 
        	GW_BATCH_EngagementRollup.settings.Override_Default_Duration__c.intvalue();
        
        date defDate;
        
        for (SObject obj : trigger.new) {
            Contact con = (Contact)obj;
            if (con.Engagement_Level_Override__c!=null) {
                Contact oldCon;
                boolean dateChgd = false;
                boolean lvlChgd = false;
                if (trigger.isUpdate) {
                    oldCon = (Contact)trigger.oldMap.get(con.Id);
                    dateChgd = (con.Engagement_Override_End_Date__c!=oldCon.Engagement_Override_End_Date__c ? true : false );
                    lvlChgd = (con.Engagement_Level_Override__c!=oldCon.Engagement_Level_Override__c ? true : false );
                }
                if ( (trigger.isInsert && con.Engagement_Override_End_Date__c==null) || (trigger.isUpdate && lvlChgd && !dateChgd) ) {
                    cons.add(con);
                }           
            }         
        }
        
        if (cons.size() > 0) {
            // optimization: do date math after first loop
            defDate = system.today().addMonths(months);
            for (Contact con:cons) {
                con.Engagement_Override_End_Date__c = defDate;
            }
        }
    }	
	
}