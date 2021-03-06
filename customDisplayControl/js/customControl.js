'use strict';
class BillingLine {
  constructor(id, date, visit, document, order, tags, displayName) {
    this.id = id;
    this.date = date;
    if (visit == null) {
      this.visit = {
        uuid: "no-visit",
        startDate: null,
        endDate: null
      }
    } else {
      this.visit = visit;
    }
    this.document = document;
    this.order = order;
    this.tags = tags;
    this.displayName = displayName;
  }
};

angular.module('bahmni.common.displaycontrol.custom')
 .service('erpService', ['$http', '$httpParamSerializer', 'sessionService', function($http, $httpParamSerializer, sessionService) {

    this.getOrder = function(id, representation) {
      var order = $http.get(Bahmni.Common.Constants.openmrsUrl + "/ws/rest/v1/erp/order/" + id + "?" + $httpParamSerializer({
        rep: representation
      }), {});
      return order;
    };

    this.getAllOrders = function(filters, representation) {
      var orders = $http.post(Bahmni.Common.Constants.openmrsUrl + "/ws/rest/v1/erp/order?" + $httpParamSerializer({
        rep: representation
      }), {
        filters: filters
      });
      return orders;
    };

    this.getInvoice = function(id, representation) {
      var invoice = $http.get(Bahmni.Common.Constants.openmrsUrl + "/ws/rest/v1/erp/invoice/" + id + "?" + $httpParamSerializer({
        rep: representation
      }), {});
      return invoice;
    };

    this.getAllInvoices = function(filters, representation) {
      var salesInvoiceFilter = {
        "field": "type",
        "comparison": "=",
        "value": "out_invoice"
      }
      filters.push(salesInvoiceFilter)
      var invoices = $http.post(Bahmni.Common.Constants.openmrsUrl + "/ws/rest/v1/erp/invoice?" + $httpParamSerializer({
        rep: representation
      }), {
        filters: filters
      });
      return invoices;
    };

  }]);
angular.module('bahmni.common.displaycontrol.custom')
  .service('openMRSVisitService', ['$http', '$httpParamSerializer', 'sessionService', function($http, $httpParamSerializer, sessionService) {

    this.getVisits = function(patientUuid, representation) {
      var visits = $http.get(Bahmni.Common.Constants.openmrsUrl + "/ws/rest/v1/visit?" + $httpParamSerializer({
        v: representation,
        patient: patientUuid
      }), {});
      return visits;
    }
  }]);


function billingStatusController($scope, $element, erpService, visitService, appService, spinner, $q) {
  $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/billingStatus.html";

  const ORDER = "ORDER"
  const INVOICE = "INVOICE"

  const NON_INVOICED = "NON INVOICED"
  const FULLY_INVOICED = "FULLY_INVOICED"
  const PARTIALLY_INVOICED = "PARTIALLY_INVOICED"

  const PAID = "PAID"
  const NOT_PAID = "NOT_PAID"

  const OVERDUE = "OVERDUE"
  const NOT_OVERDUE = "NOT_OVERDUE"

  const retireLinesConditions = $scope.config.retireLinesConditions;
  const nonApprovedConditions = $scope.config.nonApprovedConditions;
  const approvedConditions = $scope.config.approvedConditions;
  const orderExternalIdFieldName = $scope.config.orderExternalIdFieldName;

  // Temporary filter to work on non-Bahmni Odoo installs.
  // TODO: replace with '"field": "partner_uuid"' and '"value": $scope.patient.uuid'
  const patientFilter = {
    "field": $scope.config.patientUuidFieldName,
    "comparison": "=",
    "value": $scope.patient.uuid
  }
  // Initialize the filters with the patient filter.
  var invoicesFilters = [];
  var ordersFilters = [];

  var invoices = [];
  var orders = [];

  var lines = [];

  const erpOrderRepresentation = [
    "order_lines",
    "date",
    "date_order",
    "name",
    "number",
    orderExternalIdFieldName
  ]

  var retrieveErpOrders = function() {
    return erpService.getAllOrders(ordersFilters, "custom:" + erpOrderRepresentation.toString()).then(function(response) {
      orders = response.data;
    })
  }

  const erpInvoiceRepresentation = [
    "invoice_lines",
    "date",
    "state",
    "date_due",
    "number"
  ]

  var retrieveErpInvoices = function() {
    return erpService.getAllInvoices(invoicesFilters, "custom:" + erpInvoiceRepresentation.toString()).then(function(response) {
      invoices = response.data;
    })
  }

  var getOrdersAndInvoices = function() {
    return $q.all([retrieveErpOrders(), retrieveErpInvoices()]).then(function() {
      setTagsToOrderLines(orders);
      setTagsToInvoiceLines(invoices);
      setApprovalStatusToLines();
      removeRetired();
    });
  }

  var init = $q.all([getOrdersAndInvoices()]);
  init.then(function() {
    $scope.lines = lines;
  })

  $scope.initialization = init;

  var removeRetired = function() {
    lines = _.filter(lines, function(o) {
      return o.retire == false;
    })
  }

  var setApprovalStatusToLines = function() {
    lines.forEach(function(line) {
      line.approved = false;
      line.retire = false;
      approvedConditions.forEach(function(condition) {
        if (_.difference(condition, line.tags).length == 0) {
          line.approved = line.approved || true;
        }
      })
      nonApprovedConditions.forEach(function(condition) {
        if (_.difference(condition, line.tags).length == 0) {
          line.approved = line.approved || false;
        }
      })
      // set lines to retire
      retireLinesConditions.forEach(function(condition) {
        if (_.difference(condition, line.tags).length == 0) {
          line.retire = line.retire || true;
        }
      })
    })
  };

  var setTagsToOrderLines = function(orders) {
    orders.forEach(function(order) {
      order.order_lines.forEach(function(orderLine) {
        // NON INVOICED
        var tags = []
        tags.push(ORDER);
        if (orderLine.qty_invoiced == 0) {
          tags.push(NON_INVOICED);
        } else if (orderLine.qty_invoiced > 0 && orderLine.qty_to_invoice > 0) {
          // PARTIALLY_INVOICED
          tags.push(PARTIALLY_INVOICED);
        } else if (orderLine.qty_to_invoice <= 0) {
          // "orderLine.qty_to_invoice <= 0" for some reason the qty_to_invoice is negative.
          // FULLY_INVOICED
          tags.push(FULLY_INVOICED);
        }
        lines.push(new BillingLine(
          orderLine.id,
          order.date_order,
          null,
          order.name,
          orderLine[orderExternalIdFieldName],
          tags,
          orderLine.display_name
        ))
      })
    })
  };

  var setTagsToInvoiceLines = function(invoices) {
    invoices.forEach(function(invoice) {
      invoice.invoice_lines.forEach(function(invoiceLine) {
        var tags = [];
        tags.push(INVOICE)
        if (invoice.state == "paid") {
          tags.push(PAID);
        } else {
          tags.push(NOT_PAID);
        }
        if (new Date(invoice.date_due).getDate() >= new Date().getDate()) {
          tags.push(OVERDUE);
        } else {
          tags.push(NOT_OVERDUE);
        }
        var orderUuid = ""
        if (invoiceLine.origin != null) {
          orders.forEach(function(order) {
            if (order.name == invoiceLine.origin) {
              orderUuid = order[orderExternalIdFieldName];
            }
          })
        };
        lines.push(new BillingLine(
          invoiceLine.id,
          invoice.date,
          null,
          invoice.number,
          orderUuid,
          tags,
          invoiceLine.display_name
        ))
      })
      return invoices;
    });
  };
};

angular.module('bahmni.common.displaycontrol.custom')
  .directive('billingStatus', ['erpService', 'openMRSVisitService', 'appService', 'spinner', '$q', function(erpService, visitService, appService, spinner, $q) {

    var link = function($scope, $element) {
      spinner.forPromise($scope.initialization, $element);
    };

    return {
      restrict: 'E',
      controller: ['$scope', '$element', 'erpService', 'openMRSVisitService', 'appService', 'spinner', '$q', billingStatusController],
      link: link,
      template: '<section class="dashboard-section"> \
            <h2 ng-dialog-class="ngdialog ngdialog-theme-default ng-dialog-all-details-page" ng-dialog-data=\'{"section": {{section}}, "patient": {{patient}} }\' class="section-title"> \
              <span class="title-link">{{config.translationKey | translate}} </span> \
              <i class="fa"></i> \
            </h2> \
            <div> \
              <ng-include src="contentUrl" /> \
            </div>'
    }
  }])

function billingStatusVisitController($scope, visitService, appService, $q) {

  var visits = [];

  var setVisitToLines = function(lines, visits) {
    lines.forEach(function(line) {
      visits.forEach(function(visit) {
        if (visit.order == line.order) {
          line.visit = {
            uuid: visit.uuid,
            startDate: visit.startDate,
            endDate: visit.endDate
          }
        }
      })
    })
    return lines;
  }

  var groupLinesByVisit = function(linesToGroup) {
    var groupedLines = {};
    linesToGroup.forEach(function(line) {
      if (!groupedLines[line.visit.uuid]) {
        groupedLines[line.visit.uuid] = {
          visit: line.visit,
          approved: true,
          lines: [],
        };
      }
      groupedLines[line.visit.uuid].lines.push(line)
      groupedLines[line.visit.uuid].approved = groupedLines[line.visit.uuid].approved && line.approved
    })
    return groupedLines;
  }

  var getAllVisitsWithOrders = function() {
    const customRepresentation = Bahmni.ConceptSet.CustomRepresentationBuilder.build(['uuid', 'startDatetime', 'stopDatetime', 'encounters:(orders:(uuid))']);
    return visitService.getVisits($scope.patient.uuid, "custom:" + customRepresentation).then(function(response) {
      var flat = [];
      response.data.results.forEach(function(visit) {
        visit.encounters.forEach(function(encounter) {
          encounter.orders.forEach(function(order) {
            flat.push({
              uuid: visit.uuid,
              order: order.uuid,
              startDate: visit.startDatetime,
              endDate: visit.stopDatetime
            })
          })
        })
      });
      visits = flat;
    })
  }

  var init = $q.all([getAllVisitsWithOrders()])
  init.then(function() {
    $scope.lines = setVisitToLines($scope.lines, visits);
    $scope.groupedlines = groupLinesByVisit($scope.lines);
  })

  $scope.initialization = init;
}

angular.module('bahmni.common.displaycontrol.custom')
  .directive('billingStatusVisit', ['openMRSVisitService', 'appService', 'spinner', '$q', function(visitService, appService, spinner, $q) {

    var link = function($scope, $element) {
      $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/billingStatusVisit.html";
      spinner.forPromise($scope.initialization, $element);
    }

    return {
      link: link,
      restrict: 'E',
      scope: {
        lines: '=lines',
        patient: '=patient'
      },
      controller: ['$scope', 'openMRSVisitService', 'appService', '$q', billingStatusVisitController],
      template: '<div><ng-include src="contentUrl" /></div>'
    }
  }])
    .directive('birthCertificate', ['observationsService', 'appService', 'spinner', function (observationsService, appService, spinner) {
            var link = function ($scope) {
                console.log("inside birth certificate");
                var conceptNames = ["HEIGHT"];
                $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/birthCertificate.html";
                spinner.forPromise(observationsService.fetch($scope.patient.uuid, conceptNames, "latest", undefined, $scope.visitUuid, undefined).then(function (response) {
                    $scope.observations = response.data;
                }));
            };

            return {
                restrict: 'E',
                template: '<ng-include src="contentUrl"/>',
                link: link
            }
    }]).directive('deathCertificate', ['observationsService', 'appService', 'spinner', function (observationsService, appService, spinner) {
        var link = function ($scope) {
            var conceptNames = ["WEIGHT"];
            $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/deathCertificate.html";
            spinner.forPromise(observationsService.fetch($scope.patient.uuid, conceptNames, "latest", undefined, $scope.visitUuid, undefined).then(function (response) {
                $scope.observations = response.data;
            }));
        };

        return {
            restrict: 'E',
            link: link,
            template: '<ng-include src="contentUrl"/>'
        }
    }]).directive('customTreatmentChart', ['appService', 'treatmentConfig', 'TreatmentService', 'spinner', '$q', function (appService, treatmentConfig, treatmentService, spinner, $q) {
    var link = function ($scope) {
        var Constants = Bahmni.Clinical.Constants;
        var days = [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
        ];
        $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/customTreatmentChart.html";

        $scope.atLeastOneDrugForDay = function (day) {
            var atLeastOneDrugForDay = false;
            $scope.ipdDrugOrders.getIPDDrugs().forEach(function (drug) {
                if (drug.isActiveOnDate(day.date)) {
                    atLeastOneDrugForDay = true;
                }
            });
            return atLeastOneDrugForDay;
        };

        $scope.getVisitStopDateTime = function () {
            return $scope.visitSummary.stopDateTime || Bahmni.Common.Util.DateUtil.now();
        };

        $scope.getStatusOnDate = function (drug, date) {
            var activeDrugOrders = _.filter(drug.orders, function (order) {
                if ($scope.config.frequenciesToBeHandled.indexOf(order.getFrequency()) !== -1) {
                    return getStatusBasedOnFrequency(order, date);
                } else {
                    return drug.getStatusOnDate(date) === 'active';
                }
            });
            if (activeDrugOrders.length === 0) {
                return 'inactive';
            }
            if (_.every(activeDrugOrders, function (order) {
                    return order.getStatusOnDate(date) === 'stopped';
                })) {
                return 'stopped';
            }
            return 'active';
        };

        var getStatusBasedOnFrequency = function (order, date) {
            var activeBetweenDate = order.isActiveOnDate(date);
            var frequencies = order.getFrequency().split(",").map(function (day) {
                return day.trim();
            });
            var dayNumber = moment(date).day();
            return activeBetweenDate && frequencies.indexOf(days[dayNumber]) !== -1;
        };

        var init = function () {
            var getToDate = function () {
                return $scope.visitSummary.stopDateTime || Bahmni.Common.Util.DateUtil.now();
            };

            var programConfig = appService.getAppDescriptor().getConfigValue("program") || {};

            var startDate = null, endDate = null, getEffectiveOrdersOnly = false;
            if (programConfig.showDetailsWithinDateRange) {
                startDate = $stateParams.dateEnrolled;
                endDate = $stateParams.dateCompleted;
                if (startDate || endDate) {
                    $scope.config.showOtherActive = false;
                }
                getEffectiveOrdersOnly = true;
            }

            return $q.all([treatmentConfig(), treatmentService.getPrescribedAndActiveDrugOrders($scope.config.patientUuid, $scope.config.numberOfVisits,
                $scope.config.showOtherActive, $scope.config.visitUuids || [], startDate, endDate, getEffectiveOrdersOnly)])
                .then(function (results) {
                    var config = results[0];
                    var drugOrderResponse = results[1].data;
                    var createDrugOrderViewModel = function (drugOrder) {
                        return Bahmni.Clinical.DrugOrderViewModel.createFromContract(drugOrder, config);
                    };
                    for (var key in drugOrderResponse) {
                        drugOrderResponse[key] = drugOrderResponse[key].map(createDrugOrderViewModel);
                    }

                    var groupedByVisit = _.groupBy(drugOrderResponse.visitDrugOrders, function (drugOrder) {
                        return drugOrder.visit.startDateTime;
                    });
                    var treatmentSections = [];

                    for (var key in groupedByVisit) {
                        var values = Bahmni.Clinical.DrugOrder.Util.mergeContinuousTreatments(groupedByVisit[key]);
                        treatmentSections.push({visitDate: key, drugOrders: values});
                    }
                    if (!_.isEmpty(drugOrderResponse[Constants.otherActiveDrugOrders])) {
                        var mergedOtherActiveDrugOrders = Bahmni.Clinical.DrugOrder.Util.mergeContinuousTreatments(drugOrderResponse[Constants.otherActiveDrugOrders]);
                        treatmentSections.push({
                            visitDate: Constants.otherActiveDrugOrders,
                            drugOrders: mergedOtherActiveDrugOrders
                        });
                    }
                    $scope.treatmentSections = treatmentSections;
                    if ($scope.visitSummary) {
                        $scope.ipdDrugOrders = Bahmni.Clinical.VisitDrugOrder.createFromDrugOrders(drugOrderResponse.visitDrugOrders, $scope.visitSummary.startDateTime, getToDate());
                    }
                });
        };
        spinner.forPromise(init());
    };

    return {
        restrict: 'E',
        link: link,
        scope: {
            config: "=",
            visitSummary: '='
        },
        template: '<ng-include src="contentUrl"/>'
    }
}]).directive('patientAppointmentsDashboard', ['$http', '$q', '$window','appService', 'virtualConsultService', function ($http, $q, $window, appService, virtualConsultService) {
    var link = function ($scope) {
        $scope.contentUrl = appService.configBaseUrl() + "/customDisplayControl/views/patientAppointmentsDashboard.html";
        var getUpcomingAppointments = function () {
            var params = {
                q: "bahmni.sqlGet.upComingAppointments",
                v: "full",
                patientUuid: $scope.patient.uuid
            };
            return $http.get('/openmrs/ws/rest/v1/bahmnicore/sql', {
                method: "GET",
                params: params,
                withCredentials: true
            });
        };
        var getPastAppointments = function () {
            var params = {
                q: "bahmni.sqlGet.pastAppointments",
                v: "full",
                patientUuid: $scope.patient.uuid
            };
            return $http.get('/openmrs/ws/rest/v1/bahmnicore/sql', {
                method: "GET",
                params: params,
                withCredentials: true
            });
        };
        var convertUTCtoLocal = function (start_date_time, end_date_time) {
            var date = Bahmni.Common.Util.DateUtil.formatDateWithoutTime(start_date_time);
            var timeSlot = Bahmni.Common.Util.DateUtil.formatTime(start_date_time) + " - " + Bahmni.Common.Util.DateUtil.formatTime(end_date_time);
            return [date, timeSlot];
        };
        $q.all([getUpcomingAppointments(), getPastAppointments()]).then(function (response) {
            $scope.upcomingAppointments = response[0].data;
            $scope.upcomingAppointmentsUUIDs = [];
            $scope.teleconsultationAppointments = [];
            $scope.upcomingAppointmentsLinks = [];
            for (var i=0; i<$scope.upcomingAppointments.length; i++) {
                $scope.upcomingAppointmentsUUIDs[i] = $scope.upcomingAppointments[i].uuid;
                $scope.teleconsultationAppointments[i] = 'Virtual' === $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_KIND;
                delete $scope.upcomingAppointments[i].uuid;
                const [date, timeSlot] = convertUTCtoLocal($scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_START_DATE_KEY, $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_END_DATE_KEY);
                delete $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_START_DATE_KEY;
                delete $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_END_DATE_KEY;
                $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_DATE_KEY = date;
                $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_SLOT_KEY = timeSlot;
                $scope.upcomingAppointmentsLinks[i] = $scope.upcomingAppointments[i].tele_health_video_link || "";
                delete $scope.upcomingAppointments[i].DASHBOARD_APPOINTMENTS_KIND;
                delete $scope.upcomingAppointments[i].tele_health_video_link;
            }
            $scope.upcomingAppointmentsHeadings = _.keys($scope.upcomingAppointments[0]);
            $scope.pastAppointments = response[1].data;
            $scope.pastAppointmentsHeadings = _.keys($scope.pastAppointments[0]);
        });

        $scope.goToListView = function () {
            $window.open('/bahmni/appointments/#/home/manage/appointments/list');
        };
        $scope.openJitsiMeet = function (appointmentIndex) {
            var uuid = $scope.upcomingAppointmentsUUIDs[appointmentIndex];
            var link = $scope.upcomingAppointmentsLinks[appointmentIndex];
            virtualConsultService.launchMeeting(uuid, link);
        };
        $scope.showJoinTeleconsultationOption = function (appointmentIndex) {
            return $scope.upcomingAppointments[appointmentIndex].DASHBOARD_APPOINTMENTS_STATUS_KEY == 'Scheduled' &&
                    $scope.teleconsultationAppointments[appointmentIndex];
        }
    };
    return {
        restrict: 'E',
        link: link,
        scope: {
            patient: "=",
            section: "="
        },
        template: '<ng-include src="contentUrl"/>'
    };
}]);
