<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var turnsData = scenario.split("|");
						var prizeNames = (prizeNamesDesc.substring(1)).split(",");
						var convertedPrizeValues = (prizeValues.substring(1)).split("|");

						// Output Turns table.
						//const cellLayout = '000UA0M00M0A8UXDBU0MA07XU0MD0060AMUBD0MX0U05AD00M0BXU40DMA00B0D3XUA0M020D0M0A0D1';
						const countTypes = 'UDA';
						const dataTypes  = 'BMI';
						const iwTypes    = '12345678';
						const iwStr      = 'IW';
						const prizeStr   = ['Up', 'Dn', 'Acc'];

						var cellCounts = [0,0,0];
						var countIndex = -1;
						var doMoveTo   = false;
						var fromText   = '';
						var iwTurns    = [0,0,0,0,0,0,0,0];
						var moveToText = '';
						var prevTurn   = 0;
						var prizeText  = '';
						var prizeTurns = [0,0,0];
						var spinText   = '';
						var toCell     = '';
						var toText     = '';
						var turnParts  = '';
						var winPrize   = '';
						var r = [];

						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
 						r.push('<tr>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titleTurn", translations));
 						r.push('</td>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titleFromCell", translations));
 						r.push('</td>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titleSpin", translations));
 						r.push('</td>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titleToCell", translations));
 						r.push('</td>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titleMoveToCell", translations));
 						r.push('</td>');
						r.push('<td class="tablehead">');
 						r.push(getTranslationByName("titlePrize", translations));
 						r.push('</td>');
						r.push('</tr>');

						for (var turnIndex = 0; turnIndex < turnsData.length; turnIndex++)
						{
							turnParts = turnsData[turnIndex].split(",");

							for (var partIndex = 1; partIndex < turnParts.length; partIndex++)
							{
								toCell = getToCell(turnParts[partIndex], dataTypes);

								countIndex = countTypes.indexOf(toCell);

								if (countIndex != -1)
								{
									cellCounts[countIndex]++;

									if (cellCounts[countIndex] >= 4)
									{
										prizeTurns[countIndex] = turnIndex + 1;
									}
								}

								countIndex = iwTypes.indexOf(toCell);

								if (countIndex != -1)
								{
									iwTurns[countIndex] = turnIndex + 1;
								}
							}
						}

						for (var turnIndex = 0; turnIndex < turnsData.length; turnIndex++)
						{
							fromText   = (prevTurn == 0) ? getTranslationByName("startCell", translations) : prevTurn.toString();
							turnParts  = turnsData[turnIndex].split(",");
							spinText   = turnParts[0];
							toText     = getToText(turnParts[1], countTypes, dataTypes, iwTypes, iwStr, translations);
							doMoveTo   = (turnParts.length == 3);
							moveToText = (doMoveTo) ? getToText(turnParts[2], countTypes, dataTypes, iwTypes, iwStr, translations) : '';
							prizeText  = '';

							for (var partIndex = 1; partIndex < turnParts.length; partIndex++)
							{
								toCell = getToCell(turnParts[partIndex], dataTypes);
								winPrize = '';
								
								if (countTypes.indexOf(toCell) != -1)
								{
									if (prizeTurns[countTypes.indexOf(toCell)] == turnIndex + 1)
									{
										winPrize = prizeStr[countTypes.indexOf(toCell)] + cellCounts[countTypes.indexOf(toCell)];
									}
								}
								else if (iwTypes.indexOf(toCell) != -1)
								{
									if (iwTurns[iwTypes.indexOf(toCell)] == turnIndex + 1)
									{
										winPrize = iwStr + toCell;
									}
								}

								prizeText += (winPrize != '') ? ((prizeText != '') ? ' + ' : '') + convertedPrizeValues[getPrizeNameIndex(prizeNames,winPrize)] : '';
								prevTurn = parseInt(turnParts[partIndex].split(":")[0]);
							}

							r.push('<tr>');
							r.push('<td class="tablebody">' + (turnIndex+1).toString() + '</td>');
							r.push('<td class="tablebody">' + fromText + '</td>');
							r.push('<td class="tablebody">' + spinText + '</td>');
							r.push('<td class="tablebody">' + toText + '</td>');
							r.push('<td class="tablebody">' + moveToText + '</td>');
							r.push('<td class="tablebody">' + prizeText + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
						r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");


						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					// Input: "27:MU"
					// Output: "U"
					function getToCell(turnData,dataTypes)
					{
						var dataParts   = turnData.split(":");
						var toCell      = dataParts[1][0];

						if (dataTypes.indexOf(toCell) != -1)
						{
							toCell = dataParts[1][1];
						}

						return toCell;
					}

					//Input: "27:MU"
					//Output: "27 : Mystery [Up]"
					function getToText(turnData, countTypes, dataTypes, iwTypes, iwStr, translations)
					{
						const extraTurn = 'X';

						var dataParts = turnData.split(":");
						var cellTypes = countTypes + dataTypes + extraTurn + '0';
						var toCell    = dataParts[1][0];
						var toText    = dataParts[0] + ' : ' + getTranslationByName("cell" + toCell, translations);

						if (dataTypes.indexOf(toCell) != -1)
						{
							var extraText = '';
							toCell = dataParts[1][1];

							if (toCell == extraTurn || countTypes.indexOf(toCell) != -1)
							{
								extraText = getTranslationByName("cell" + toCell, translations);
							}
							else if (iwTypes.indexOf(toCell) != -1)
							{
								extraText = iwStr + toCell;
							}

							toText += ' [' + extraText + ']'; 
						}

						return toText;
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
