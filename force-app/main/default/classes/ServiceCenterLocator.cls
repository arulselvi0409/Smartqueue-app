public with sharing class ServiceCenterLocator {

    public class CenterWrapper {

        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;

        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String centerType;
        @AuraEnabled public String area;

        @AuraEnabled public Decimal distanceFormatted;
        @AuraEnabled public Boolean isFull;

        @AuraEnabled public Integer waitingCount;
        @AuraEnabled public Integer estimatedWait;

        @AuraEnabled public Integer capacity;
        @AuraEnabled public String capacityStatus;
    }

    @AuraEnabled(cacheable=true)
    public static List<CenterWrapper> getNearestCenters(
        Decimal userLat,
        Decimal userLong,
        String serviceType
    ){

        List<Service_Center__c> centers;

        if(String.isNotBlank(serviceType)){
            centers = [
                SELECT Id,
                       Name,
                       Type__c,
                       Area__c,
                       Capacity__c,
                       Geolocation__Latitude__s,
                       Geolocation__Longitude__s
                FROM Service_Center__c
                WHERE Type__c = :serviceType
            ];
        }
        else{
            centers = [
                SELECT Id,
                       Name,
                       Type__c,
                       Area__c,
                       Capacity__c,
                       Geolocation__Latitude__s,
                       Geolocation__Longitude__s
                FROM Service_Center__c
            ];
        }

        List<CenterWrapper> result = new List<CenterWrapper>();

        Map<Id,Integer> waitingMap = new Map<Id,Integer>();

        for(AggregateResult ar : [
            SELECT Service_Center__c sc, COUNT(Id) cnt
            FROM Token__c
            WHERE Status__c = 'Waiting'
            GROUP BY Service_Center__c
        ]){
            waitingMap.put((Id) ar.get('sc'), (Integer) ar.get('cnt'));
        }

        for(Service_Center__c c : centers){

            CenterWrapper w = new CenterWrapper();

            w.Id = c.Id;
            w.Name = c.Name;
            w.centerType = c.Type__c;
            w.area = c.Area__c;

            w.latitude = c.Geolocation__Latitude__s;
            w.longitude = c.Geolocation__Longitude__s;

            w.capacity = (Integer)c.Capacity__c;

            if(userLat != null && userLong != null &&
               c.Geolocation__Latitude__s != null &&
               c.Geolocation__Longitude__s != null){

                Decimal distance = getDistance(
                    userLat,
                    userLong,
                    c.Geolocation__Latitude__s,
                    c.Geolocation__Longitude__s
                );

                w.distanceFormatted = distance.setScale(2);
            }

            Integer waiting = waitingMap.containsKey(c.Id)
                ? waitingMap.get(c.Id)
                : 0;

            w.waitingCount = waiting;

            /* Capacity Status Logic */

            if(w.capacity != null){

                if(waiting >= w.capacity){
                    w.capacityStatus = 'Full';
                    w.isFull = true;
                }
                else if(waiting >= (w.capacity * 0.8)){
                    w.capacityStatus = 'Almost Full';
                    w.isFull = false;
                }
                else{
                    w.capacityStatus = 'Available';
                    w.isFull = false;
                }
            }

            List<Token__c> latestToken = [
                SELECT Estimated_Wait_Time__c
                FROM Token__c
                WHERE Service_Center__c = :c.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if(!latestToken.isEmpty()){
                w.estimatedWait =
                    (Integer) latestToken[0].Estimated_Wait_Time__c;
            }
            else{
                w.estimatedWait = 0;
            }

            result.add(w);
        }

        result.sort(new DistanceComparator());

        return result;
    }

    private static Decimal getDistance(
        Decimal lat1,
        Decimal lon1,
        Decimal lat2,
        Decimal lon2
    ){

        Double earthRadius = 6371.0;

        Double dLat = ((Double)(lat2 - lat1)) * (Math.PI / 180);
        Double dLon = ((Double)(lon2 - lon1)) * (Math.PI / 180);

        Double rLat1 = ((Double)lat1) * (Math.PI / 180);
        Double rLat2 = ((Double)lat2) * (Math.PI / 180);

        Double a =
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(rLat1) *
            Math.cos(rLat2) *
            Math.sin(dLon/2) *
            Math.sin(dLon/2);

        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        Double distance = earthRadius * c;

        return Decimal.valueOf(distance);
    }

    public class DistanceComparator implements Comparator<CenterWrapper>{

        public Integer compare(CenterWrapper a, CenterWrapper b){

            if(a.distanceFormatted == null) return 1;
            if(b.distanceFormatted == null) return -1;

            if(a.distanceFormatted > b.distanceFormatted) return 1;
            if(a.distanceFormatted < b.distanceFormatted) return -1;

            return 0;
        }
    }
}