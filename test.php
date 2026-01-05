<?php
$targetList = array( "target_type" => "ITINERARY",
                     "targets"     => array( array("trip_id" => 81
                                                  , "itinerary_id" => 121
                                                  , "customer_id" => 2
                                                  )
                                           , array("trip_id" => 81
                                                  , "itinerary_id" => 121
                                                  , "customer_id" => 12
                                                  )
                                           , array("trip_id" => 81
                                                  , "itinerary_id" => 121
                                                  , "customer_id" => 72
                                                  )
                                           )
                    );

print_r($targetList);
$targetColumns = array_column($targetList["targets"], "trix_id", "itinerary_id");
print_r($targetColumns);
?>
