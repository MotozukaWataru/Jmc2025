<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!--
    【1_seg_cycle.xslt の目的】

    譜本文 (<ab>) 直下の要素列を、拍子記号「百」を手がかりに
    <seg type="cycle"> 単位に分割する。

    - <ab> の子要素を走査し、以下のように cycle を定義する。
      * 先頭が <metamark>百</metamark> の場合：
          百から次の百の直前までを 1 cycle とし、@n=1,2,3,... を付与する。
      * 先頭が百以外の場合：
          最初の百の直前までを cycle n="0" とし、
          その後は百から百の直前までを n=1,2,3,... として分割する。
      * 百が 1 つも現れない場合：
          segmentation は行わず、<ab> の中身をそのまま出力する。
  -->
  
  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       [1] <ab> 内の要素列を cycle に分割
       ============================== -->
  
  <xsl:template match="tei:ab">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- 先頭の子要素 -->
      <xsl:variable name="first" select="*[1]"/>
      
      <xsl:choose>
        <!-- 子要素が存在しない場合はそのまま（中身なし） -->
        <xsl:when test="not($first)"/>
        
        <xsl:otherwise>
          <!-- 最初に現れる <metamark>百</metamark> -->
          <xsl:variable name="first-hyaku"
            select="tei:metamark[text()='百'][1]"/>
          
          <xsl:choose>
            <!-- [1-1] 先頭が百で始まる場合：cycle は 1 から -->
            <xsl:when test="$first[self::tei:metamark[text()='百']]">
              <xsl:call-template name="cycle-from-hyaku">
                <xsl:with-param name="start" select="$first"/>
                <xsl:with-param name="index" select="1"/>
              </xsl:call-template>
            </xsl:when>
            
            <!-- [1-2] 先頭が百以外で、途中に百が現れる場合 -->
            <xsl:when test="$first-hyaku">
              <!-- cycle n="0"：先頭〜最初の百の直前まで -->
              <seg type="cycle" xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="n">0</xsl:attribute>
                <xsl:call-template name="emit-until">
                  <xsl:with-param name="node" select="$first"/>
                  <xsl:with-param name="stop" select="$first-hyaku"/>
                </xsl:call-template>
              </seg>
              
              <!-- cycle n>=1：最初の百から順に -->
              <xsl:call-template name="cycle-from-hyaku">
                <xsl:with-param name="start" select="$first-hyaku"/>
                <xsl:with-param name="index" select="1"/>
              </xsl:call-template>
            </xsl:when>
            
            <!-- [1-3] 百が一度も現れない場合：中身をそのまま出力 -->
            <xsl:otherwise>
              <xsl:apply-templates select="node()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- [1-4] 百から次の百の直前までを 1 cycle として出力 -->
  <xsl:template name="cycle-from-hyaku">
    <xsl:param name="start"/>
    <xsl:param name="index"/>
    
    <xsl:if test="$start">
      <!-- start は <metamark>百</metamark> であることを想定 -->
      <!-- 次の百（あれば） -->
      <xsl:variable name="next-hyaku"
        select="$start/following-sibling::tei:metamark[text()='百'][1]"/>
      
      <seg type="cycle" xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:attribute name="n">
          <xsl:value-of select="$index"/>
        </xsl:attribute>
        
        <!-- start から next-hyaku の直前までをこの cycle に含める -->
        <xsl:call-template name="emit-until">
          <xsl:with-param name="node" select="$start"/>
          <xsl:with-param name="stop" select="$next-hyaku"/>
        </xsl:call-template>
      </seg>
      
      <!-- 次の cycle：next-hyaku を先頭に再帰 -->
      <xsl:if test="$next-hyaku">
        <xsl:call-template name="cycle-from-hyaku">
          <xsl:with-param name="start" select="$next-hyaku"/>
          <xsl:with-param name="index" select="$index + 1"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- [補助] node から stop の直前までの要素を順に出力する -->
  <xsl:template name="emit-until">
    <xsl:param name="node"/>
    <xsl:param name="stop"/>
    
    <xsl:if test="$node">
      <!-- 自分自身が stop ならここで終了（stop 自体は含めない） -->
      <xsl:if test="not($stop and generate-id($node) = generate-id($stop))">
        <xsl:apply-templates select="$node"/>
        
        <!-- 次の兄弟要素 -->
        <xsl:variable name="next" select="$node/following-sibling::*[1]"/>
        
        <!-- 次が stop でなければ続ける -->
        <xsl:if test="$next and not($stop and generate-id($next) = generate-id($stop))">
          <xsl:call-template name="emit-until">
            <xsl:with-param name="node" select="$next"/>
            <xsl:with-param name="stop" select="$stop"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>



