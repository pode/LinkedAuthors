<?xml version="1.0" encoding="UTF-8"?>

<!--
FRBR2RDF.XLS - xslt stylesheet to render marcxml to rdf
Author: Benjamin Rokseth
Contact: benjamin@deichman.no
Date: 28.05.2010
Version XSL file: v02
Vocabulary: http://www.bibpode.no/

Issues: 
	dct:title, pode:subtitle, pode:responsibility has sometimes " in it, need to translate away quotes as they break rdf
		solution: translate(., '&quot;','')
	260 $b dct:issued needs to remove unwanted chars, translate away everything except numbers
		solution: translate(.,translate(.,'0123456789',''),'') 
	082 $a contains dewey and sometimes unwanted content. 
		solution: check for digit in 3rd position: xsl:if test="substring(.,3,1) &gt;= '0' and substring(.,3,1) &lt;= '9'"
				  + translate . in isbn to _ for compliance to rdf
	008 $b somtimes contains 'mul' which means multi language codes of 3 digits with no separation between are in 041
		solution: double test: if pos 36-38 is 'mul' fetch datafield 041, call template splitstring to get three and three chars:
				  <xsl:call-template name="splitstring">
							<xsl:with-param name="string" select="//datafield[@tag = '041']/subfield[@code = 'a']"/>
							<xsl:with-param name="position" select="1"/>
							<xsl:with-param name="namespaces" select="'dct:language&#09;&#09;instance:'"/>
	    also in a few places there is no language code, so it all needs to be wrapped in an IF to check if it isn't only spaces:
		solution: <xsl:if test="string-length(normalize-space(substring(., 36 ,3))) != 0">
	    						
	019 $b is physical format and sometimes contains comma separated content
		solution: <xsl:call-template name="divide">
								<xsl:with-param name="string" select="."/>
								<xsl:with-param name="namespaces" select="'dct:format&#09;&#09;&#09;ff:'"/>
								
	019 $d is literary format and contains one char per format
		solution: <xsl:call-template name="splitstring">
							<xsl:with-param name="string" select="."/>
							<xsl:with-param name="position" select="1"/>
							<xsl:with-param name="namespaces" select="'pode:literaryFormat&#09;lf:'"/>
							<xsl:with-param name="splitcharnumber" select="1"/>
	instances created need to remove unwanted characters.
		solution: call template removeunwantedcharacters:
		translate(translate(translate(translate(translate(translate(translate(translate($stringIn,'æ','ae'),'Æ','Ae'),'ø','oe'),'Ø','Oe'),'å','aa'),'Å','Aa'),'\,',''),'-. ´[]','______')
-->

<xsl:stylesheet version="1.0" 
			xmlns:owl="http://www.w3.org/2002/07/owl#"
			xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
			xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
			xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
			xmlns:foaf="http://xmlns.com/foaf/0.1/"
			xmlns:xfoaf="http://www.foafrealm.org/xfoaf/0.1/"
			xmlns:lingvoj="http://www.lingvoj.org/ontology#"
			xmlns:mm="http://musicbrainz.org/mm/mm-2.1#" 
			xmlns:dcmi="http://dublincore.org/documents/dcmi-terms/"
			xmlns:dcmitype="http://dublincore.org/documents/dcmi-type-vocabulary/"
			xmlns:skos="http://www.w3.org/2004/02/skos/core#"
			xmlns:geo="http://www.geonames.org/ontology#"			
			xmlns:dct="http://purl.org/dc/elements/1.1/"
			xmlns:dc="http://purl.org/dc/elements/1.1/"
			xmlns:cc="http://web.resource.org/cc/"
			
			xmlns:pode="http://www.bibpode.no/vocabulary#"
			xmlns:ff="http://www.bibpode.no/ff/"
			xmlns:lf="http://www.bibpode.no/lf/"
			xmlns:vann="http://purl.org/vocab/vann/"
			xmlns:frbr="http://idi.ntnu.no/frbrizer"
			xmlns:sublima="http://xmlns.computas.com/sublima#"
			xmlns:owl2xml="http://www.w3.org/2006/12/owl2-xml#"
			xmlns:movie="http://data.linkedmdb.org/resource/movie/"	>

	<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
	
<!-- START PARSING -->	
	<xsl:template match="/">

<xsl:text>&#09;</xsl:text><xsl:text>&#64;</xsl:text>prefix rdf: 		<xsl:text>&#60;</xsl:text>http://www.w3.org/1999/02/22-rdf-syntax-ns#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix rdfs: 		<xsl:text>&#60;</xsl:text>http://www.w3.org/2000/01/rdf-schema#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix owl: 		<xsl:text>&#60;</xsl:text>http://www.w3.org/2002/07/owl#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix foaf: 		<xsl:text>&#60;</xsl:text>http://xmlns.com/foaf/0.1/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix xfoaf: 		<xsl:text>&#60;</xsl:text>http://www.foafrealm.org/xfoaf/0.1/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix lingvoj: 	<xsl:text>&#60;</xsl:text>http://www.lingvoj.org/ontology#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix dcmitype: 	<xsl:text>&#60;</xsl:text>http://purl.org/dc/dcmitype/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix dcmi: 		<xsl:text>&#60;</xsl:text>http://purl.org/dc/dcmitype/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix dct: 		<xsl:text>&#60;</xsl:text>http://purl.org/dc/terms/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix dc: 		<xsl:text>&#60;</xsl:text>http://purl.org/dc/terms/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix skos: 		<xsl:text>&#60;</xsl:text>http://www.w3.org/2004/02/skos/core#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix xsd: 		<xsl:text>&#60;</xsl:text>http://www.w3.org/2001/XMLSchema#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix mm: 		<xsl:text>&#60;</xsl:text>http://musicbrainz.org/mm/mm-2.1#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix cc: 		<xsl:text>&#60;</xsl:text>http://creativecommons.org/ns#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix geo:		<xsl:text>&#60;</xsl:text>http://www.geonames.org/ontology#<xsl:text>&#62; .</xsl:text> 
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix wgs84_pos:	<xsl:text>&#60;</xsl:text>http://www.w3.org/2003/01/geo/wgs84_pos#<xsl:text>&#62; .</xsl:text> 
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix ns:			<xsl:text>&#60;</xsl:text>http://creativecommons.org/ns#<xsl:text>&#62; .</xsl:text> 
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix owl2xml:	<xsl:text>&#60;</xsl:text>http://www.w3.org/2006/12/owl2-xml#<xsl:text>&#62; .</xsl:text> 
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix movie:		<xsl:text>&#60;</xsl:text>http://data.linkedmdb.org/resource/movie/<xsl:text>&#62; .</xsl:text>
<!-- pode specific namespaces -->		
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix instance:	<xsl:text>&#60;</xsl:text>http://www.bibpode.no/instance/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix pode:		<xsl:text>&#60;</xsl:text>http://www.bibpode.no/vocabulary#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix ff:			<xsl:text>&#60;</xsl:text>http://www.bibpode.no/ff/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix lf:			<xsl:text>&#60;</xsl:text>http://www.bibpode.no/lf/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix vann:		<xsl:text>&#60;</xsl:text>http://purl.org/vocab/vann/<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix frbr:		<xsl:text>&#60;</xsl:text>http://purl.org/vocab/frbr/core#<xsl:text>&#62; .</xsl:text>
	<xsl:text>&#10;&#09;&#64;</xsl:text>prefix sublima:	<xsl:text>&#60;</xsl:text>http://xmlns.computas.com/sublima#<xsl:text>&#62; .</xsl:text>
		<xsl:text>&#10;&#09;</xsl:text><xsl:text>&#10;</xsl:text><xsl:text>&#10;</xsl:text>

<!-- FIRST RUN: work, expression, manifestation & person -->
			<xsl:apply-templates select="collection/record[@type = '4.2'][@label = 'Work']"/>
			<xsl:apply-templates select="collection/record[@type = '4.3'][@label = 'Expression']"/>
			<xsl:apply-templates select="collection/record[@type = '4.4'][@label = 'Manifestation']"/>
			<xsl:apply-templates select="collection/record[@type = '4.6'][@label = 'Person']"/>		
<!-- SECOND RUN: instances -->				
	<!-- publicationPlace foaf:Organizaion-->
			<xsl:apply-templates select="collection/record[@type = '4.4'][@label = 'Manifestation']/datafield[@tag = 260]/subfield[@code = 'a']"/>		
	<!-- publisher geo:Feature -->
			<xsl:apply-templates select="collection/record[@type = '4.4'][@label = 'Manifestation']/datafield[@tag = 260]/subfield[@code = 'b']"/>		
    <!-- language lingvoj:Lingvo -->			
			<xsl:apply-templates select="collection/record/controlfield[@tag = '008']"/>		
			<xsl:text>&#10;</xsl:text>
	</xsl:template>
<!--	END MAIN TEMPLATE		-->


<!-- 	START WORK TEMPLATE -->
	<xsl:template match="collection/record[@type = '4.2'][@label = 'Work']">
		<dct:uri><xsl:text>pode:</xsl:text><xsl:value-of select="@id"/><xsl:text></xsl:text></dct:uri>
		<rdf:type><xsl:text>&#10;&#09;</xsl:text>a			frbr:Work ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>dct:source		pode:Deichmanarkiv</dct:source>
<!-- Her testes datafield mot marc 600, 700 og 740 for tittel --> 
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 700">
<!-- test subfield for code 't'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 't'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>
				<xsl:for-each select="datafield">
			<xsl:if test="@tag = 740">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
			<xsl:if test="@tag = 600">
<!-- test subfield for code 't'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 't'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 245 for tittel,undertittel & ansvar-->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 245">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'b'">
				<dct:subtitle><xsl:text> ;&#10;&#09;</xsl:text>pode:subtitle 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:subtitle>
				</xsl:if>

<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'c'">
				<pode:responsibility><xsl:text> ;&#10;&#09;</xsl:text>pode:responsibility 	 """<xsl:value-of select="translate(., '&quot;','')"/>"""</pode:responsibility>
				</xsl:if>
								
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 082 for klassifisering -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 082">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
<!-- test code a for digit in position 3 = dewey code -->				
					<xsl:if test="substring(.,3,1) &gt;= '0' and substring(.,3,1) &lt;= '9'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>pode:classification		pode:<xsl:value-of select="translate(.,'.','_')"/></dct:title>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
<!-- her testes "Work" mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.1.1.F'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>frbr:realization		pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.1.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>dct:creator 	 	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.3.5.R' or @type = '5.2.3.1.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>frbr:subject 	 	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.3.1.F'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>pode:subjectOf 	 	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
			</xsl:for-each>
		<xsl:text> .&#10;&#10;</xsl:text>
	</xsl:template>
<!-- END WORK TEMPLATE-->

<!-- 	START EXPRESSION TEMPLATE-->
	<xsl:template match="collection/record[@type = '4.3'][@label = 'Expression']">
		<dct:uri><xsl:text>pode:</xsl:text><xsl:value-of select="@id"/><xsl:text></xsl:text></dct:uri><xsl:text>&#10;&#09;</xsl:text>
		<rdf:type>a			frbr:Expression ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>dct:source		pode:Deichmanarkiv</dct:source>
<!-- Her testes controlfield mot marc 008 for lokal språkkode --> 
		<xsl:for-each select="controlfield">
			<xsl:if test="@tag = 008">
<!-- extra test: if 35-37 is 'mul' fetch datafield 041 -->
				<xsl:choose> 
					<xsl:when test="substring(., 36 ,3) = 'mul'">
						<xsl:call-template name="splitstring">
							<xsl:with-param name="string" select="//datafield[@tag = '041']/subfield[@code = 'a']"/>
							<xsl:with-param name="position" select="1"/>
							<xsl:with-param name="namespaces" select="'dct:language&#09;&#09;instance:'"/>
							<xsl:with-param name="splitcharnumber" select="3"/>
						</xsl:call-template>
					
					</xsl:when>
					<xsl:otherwise>
<!-- need IF here in case no content -->
						<xsl:if test="string-length(normalize-space(substring(., 36 ,3))) != 0">
							<dct:language><xsl:text> ;&#10;&#09;</xsl:text>dct:language	 	instance:<xsl:value-of select="substring(., 36 ,3)"/></dct:language>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>

<!-- Her testes datafield mot marc 700 og 740 for tittel --> 
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 700">
<!-- test subfield for code 't'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 't'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title			"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 740">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title			"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 019">
<!-- test subfield for code 'b'  -->
			<xsl:for-each select="subfield">
				<xsl:choose>
					<xsl:when test="@code = 'b'">
							<xsl:call-template name="divide">
								<xsl:with-param name="string" select="."/>
								<xsl:with-param name="namespaces" select="'dct:format&#09;&#09;&#09;ff:'"/>
							</xsl:call-template>
					</xsl:when>
<!-- test subfield for code 'd' literary format -->
					<xsl:when test="@code = 'd'">
						<xsl:call-template name="splitstring">
							<xsl:with-param name="string" select="."/>
							<xsl:with-param name="position" select="1"/>
							<xsl:with-param name="namespaces" select="'pode:literaryFormat&#09;lf:'"/>
							<xsl:with-param name="splitcharnumber" select="1"/>
						</xsl:call-template>
					
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
<!-- her testes datafield mot marc 245 for tittel,undertittel & ansvar-->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 245">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title			"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'b'">
				<dct:subtitle><xsl:text> ;&#10;&#09;</xsl:text>pode:subtitle 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:subtitle>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'c'">
				<pode:responsibility><xsl:text> ;&#10;&#09;</xsl:text>pode:responsibility	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</pode:responsibility>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>
		
<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.1.1.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>frbr:realizationOf	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.1.2.F'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>frbr:embodiment		pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.3.T.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>pode:translator 	 	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.3.N.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>pode:reader		pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
	<xsl:text> .&#10;&#10;</xsl:text>		
	</xsl:template>
		
<!-- END EXPRESSION TEMPLATE -->		
		
<!-- 	START MANIFESTATION TEMPLATE-->
	<xsl:template match="collection/record[@type = '4.4'][@label = 'Manifestation']">
		<dct:uri><xsl:text>pode:</xsl:text><xsl:value-of select="@id"/><xsl:text></xsl:text></dct:uri><xsl:text>&#10;&#09;</xsl:text>
		<rdf:type>a			frbr:Manifestation ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>dct:source		pode:Deichmanarkiv</dct:source>



<!-- 020 $a pode:isbn -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 020">
<!-- test subfield for code 'b'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:isbn><xsl:text> ;&#10;&#09;</xsl:text>pode:isbn 	 	"<xsl:value-of  select="."/>"^^xsd:string</dct:isbn>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 240 for tittel -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 240">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 245 for tittel,undertittel & ansvar-->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 245">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:title><xsl:text> ;&#10;&#09;</xsl:text>dct:title 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:title>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'b'">
				<dct:subtitle><xsl:text> ;&#10;&#09;</xsl:text>pode:subtitle 	 """<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:subtitle>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'c'">
				<pode:responsibility><xsl:text> ;&#10;&#09;</xsl:text>pode:responsibility		"""<xsl:value-of select="translate(., '&quot;','')"/>"""</pode:responsibility>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>
		
<!-- her testes datafield mot marc 260 for publikasjonssted,utgiver & utgiverår-->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 260">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<geo:feature><xsl:text> ;&#10;&#09;</xsl:text>pode:publicationPlace	instance:<xsl:call-template name="replaceUnwantedCharacters">			<xsl:with-param name="stringIn" select="."/></xsl:call-template></geo:feature>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'b'">
				<dct:publisher><xsl:text> ;&#10;&#09;</xsl:text>pode:publisher 	 	instance:<xsl:call-template name="replaceUnwantedCharacters">			<xsl:with-param name="stringIn" select="."/></xsl:call-template></dct:publisher>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'c'">
<!-- NB: xsd:int demands whole integer, thus translate away everything except the four first numbers -->
<!-- also test if content not returns empty -->
					<xsl:if test="substring(translate(.,translate(.,'0123456789',''),''), 1 ,4)">
						<dct:issued><xsl:text> ;&#10;&#09;</xsl:text>dct:issued			"<xsl:value-of select="substring(translate(.,translate(.,'0123456789',''),''), 1 ,4)"/>"^^xsd:int</dct:issued>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 300 for fysisk beskrivelse -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 300">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<dct:description><xsl:text> ;&#10;&#09;</xsl:text>pode:physicalDescription	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:description>
				</xsl:if>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.1.2.R'">
			<xsl:for-each select="@href">
				<xsl:text> ;&#10;&#09;</xsl:text>frbr:embodimentOf 	 	pode:<xsl:value-of select="."/>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
	<xsl:text> .&#10;&#10;</xsl:text>		
	</xsl:template>
		
<!-- END MANIFESTATION TEMPLATE -->		

<!-- 	START PERSON TEMPLATE-->
	<xsl:template match="collection/record[@type = '4.6'][@label = 'Person']">
		<dct:uri><xsl:text>pode:</xsl:text><xsl:value-of select="@id"/><xsl:text></xsl:text></dct:uri><xsl:text>&#10;&#09;</xsl:text>
		<rdf:type>a			foaf:Person ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>dct:source		pode:Deichmanarkiv</dct:source>


<!-- her testes datafield mot marc 100 for navn, levetid & nasjonalitet -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 100">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<foaf:name><xsl:text> ;&#10;&#09;</xsl:text>foaf:name 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</foaf:name>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'b'">
				<pode:lifespan><xsl:text> ;&#10;&#09;</xsl:text>pode:lifespan 	 "<xsl:value-of select="."/>"^^xsd:string</pode:lifespan>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'j'">
				<pode:nationality><xsl:text> ;&#10;&#09;</xsl:text>pode:nationality		"<xsl:value-of select="."/>"^^xsd:string</pode:nationality>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>

<!-- her testes datafield mot marc 600 for navn, levetid & nasjonalitet -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 600">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<foaf:name><xsl:text> ;&#10;&#09;</xsl:text>foaf:name 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</foaf:name>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'd'">
				<pode:lifespan><xsl:text> ;&#10;&#09;</xsl:text>pode:lifespan 	 "<xsl:value-of select="."/>"^^xsd:string</pode:lifespan>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'j'">
				<pode:nationality><xsl:text> ;&#10;&#09;</xsl:text>pode:nationality		"<xsl:value-of select="."/>"^^xsd:string</pode:nationality>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>
		
<!-- her testes datafield mot marc 700 for navn, levetid & nasjonalitet -->
		<xsl:for-each select="datafield">
			<xsl:if test="@tag = 700">
<!-- test subfield for code 'a'  -->
			<xsl:for-each select="subfield">
				<xsl:if test="@code = 'a'">
				<foaf:name><xsl:text> ;&#10;&#09;</xsl:text>foaf:name 	 	"""<xsl:value-of select="translate(., '&quot;','')"/>"""</foaf:name>
				</xsl:if>
<!-- test subfield for code 'b'  -->				
				<xsl:if test="@code = 'd'">
				<pode:lifespan><xsl:text> ;&#10;&#09;</xsl:text>pode:lifespan 	 "<xsl:value-of select="."/>"^^xsd:string</pode:lifespan>
				</xsl:if>
<!-- test subfield for code 'c'  -->				
				<xsl:if test="@code = 'j'">
				<pode:nationality><xsl:text> ;&#10;&#09;</xsl:text>pode:nationality		"<xsl:value-of select="."/>"^^xsd:string</pode:nationality>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		</xsl:for-each>
		
<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.1.F'">
			<xsl:for-each select="@href">
				<pode:creatorOf><xsl:text> ;&#10;&#09;</xsl:text>pode:creatorOf 	 	pode:<xsl:value-of select="."/></pode:creatorOf>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.3.5.F'">
			<xsl:for-each select="@href">
				<pode:subjectOf><xsl:text> ;&#10;&#09;</xsl:text>pode:subjectOf 	 	pode:<xsl:value-of select="."/></pode:subjectOf>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.3.N.F'">
			<xsl:for-each select="@href">
				<pode:readerOf><xsl:text> ;&#10;&#09;</xsl:text>pode:readerOf 	 	pode:<xsl:value-of select="."/></pode:readerOf>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>

<!-- her testes mot node relationship -->
		<xsl:for-each select="relationship">
			<xsl:if test="@type = '5.2.2.3.T.F'">
			<xsl:for-each select="@href">
				<pode:translatorOf><xsl:text> ;&#10;&#09;</xsl:text>pode:translatorOf 	 	pode:<xsl:value-of select="."/></pode:translatorOf>
			</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		
	<xsl:text> .&#10;&#10;</xsl:text>		
	</xsl:template>
	
<!-- END PERSON TEMPLATE -->		


<!-- START INSTANCE TEMPLATES -->
<!-- dct:publisher -->
	<xsl:template match="collection/record[@type = '4.4'][@label = 'Manifestation']/datafield[@tag = 260]/subfield[@code = 'b']">
	<xsl:for-each select=".">
		<dct:uri><xsl:text>instance:</xsl:text>
		<xsl:call-template name="replaceUnwantedCharacters">
			<xsl:with-param name="stringIn" select="."/>
		</xsl:call-template>
		</dct:uri>
		<xsl:text>&#10;&#09;</xsl:text>
		<rdf:type>a			foaf:Organization ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>foaf:name		"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:source>
	<xsl:text> .&#10;&#10;</xsl:text>
	</xsl:for-each>
	</xsl:template>

<!-- pode:publicationPlace -->
	<xsl:template match="collection/record[@type = '4.4'][@label = 'Manifestation']/datafield[@tag = 260]/subfield[@code = 'a']">
	<xsl:for-each select=".">
		<dct:uri><xsl:text>instance:</xsl:text>
		<xsl:call-template name="replaceUnwantedCharacters">
			<xsl:with-param name="stringIn" select="."/>
		</xsl:call-template>
		</dct:uri>
		<xsl:text>&#10;&#09;</xsl:text>
		<rdf:type>a			geo:Feature ;</rdf:type>
		<dct:source><xsl:text>&#10;&#09;</xsl:text>geo:name		"""<xsl:value-of select="translate(., '&quot;','')"/>"""</dct:source>
	<xsl:text> .&#10;&#10;</xsl:text>
	</xsl:for-each>
	</xsl:template>

<!-- lingvo:Lingvoj -->
	<xsl:template match="collection/record/controlfield[@tag = '008']">
		<xsl:if test="string-length(normalize-space(substring(., 36 ,3))) != 0">
			<dct:uri><xsl:text>instance:</xsl:text>
			<xsl:value-of select="substring(., 36, 3)"/>
			</dct:uri>
			<xsl:text>&#10;&#09;</xsl:text>
			<lingvoj:Lingvo>a			lingvoj:Lingvo</lingvoj:Lingvo>
		<xsl:text> .&#10;&#10;</xsl:text>
		</xsl:if>
	</xsl:template>


<!-- STRING MANAGEMENT TEMPLATES -->

<!-- string replace 'æ' 'ø' 'å' and replace unwanted characters with '_' 
	INPUT PARAMETERS 
	stringIn	input string to process
-->
	<xsl:template name="replaceUnwantedCharacters">
		  <xsl:param name="stringIn"/>
		  <xsl:value-of select="translate(translate(translate(translate(translate(translate(translate(translate(translate(translate(translate(translate($stringIn,'æ','ae'), '&quot;', ''), &quot;'&quot;,''),'&amp;',''),'Æ','Ae'),'ø','oe'),'Ø','Oe'),'å','aa'),'Å','Aa'),'?',''),'\,',''),'/-. ´[]','_______')"/>
	</xsl:template>


<!-- template for splitting up multilanguage strings in field 041
	INPUT PARAMETERS 
	string		input string to process
	position 	position of character to start
	namespaces 	string for namespaces output for predicate and object
	splitcharnumber number of characters in each source segment
--> 
	<xsl:template name="splitstring">
			<xsl:param name="position"/>
			<xsl:param name="string"/>
			<xsl:param name="namespaces"/>
			<xsl:param name="splitcharnumber"/>
				<xsl:if test="$position &lt;= string-length($string)">
				<dct:language><xsl:text> ;&#10;&#09;</xsl:text><xsl:value-of select="$namespaces"/><xsl:value-of select="substring($string, $position, $splitcharnumber)"/></dct:language>
					<xsl:call-template name="splitstring">
						<xsl:with-param name="string" select="$string"/>
						<xsl:with-param name="position" select="$position + $splitcharnumber"/>
						<xsl:with-param name="namespaces" select="$namespaces"/>
						<xsl:with-param name="splitcharnumber" select="$splitcharnumber"/>
					</xsl:call-template>
				</xsl:if>
	</xsl:template>

<!-- template to divide comma-separated values 
	INPUT PARAMETERS 
	string		input string to process
	namespaces 	string for namespaces output for predicate and object
--> 
 <xsl:template name="divide">
	<xsl:param name="string"/>
	<xsl:param name="namespaces"/>
		<xsl:choose>
			<xsl:when test="contains($string,',')">
	    <!-- Select the first value to process -->
              <dct:format><xsl:text> ;&#10;&#09;</xsl:text><xsl:value-of select="$namespaces"/><xsl:value-of select="substring-before($string,',')"/></dct:format>
            <!-- Recurse with remainder of string -->
				<xsl:call-template name="divide">
					<xsl:with-param name="string" select="substring-after($string,',')"/>
					<xsl:with-param name="namespaces" select="$namespaces"/>
				</xsl:call-template>
			</xsl:when>
			<!-- This is the last value so we don't recurse -->
			<xsl:otherwise>
				<dct:format><xsl:text> ;&#10;&#09;</xsl:text><xsl:value-of select="$namespaces"/><xsl:value-of select="$string"/></dct:format>
			</xsl:otherwise>
		</xsl:choose>
 </xsl:template>	
		
</xsl:stylesheet>



