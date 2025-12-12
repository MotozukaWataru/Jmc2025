<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!--
    【2_seg_multi.xslt の目的】

    1_seg_cycle.xslt の出力（<seg type="cycle">）を受け取り、
    各 cycle の内部を、拍子記号「◦」「一」を手がかりに
    <seg type="multi"> 単位に分割する。

    - 対象：<seg type="cycle"> の直下の子要素列。
    - ルール：
      * 「◦」「一」そのものは multi の外側に残す。
      * 「◦」「一」の間に挟まれた要素列を 1 つの multi とする。
      * cycle の先頭や末尾の端数も、それぞれ 1 つの multi として扱う。
  -->
  
  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       [1] cycle 内の要素列を multi に分割
       ============================== -->
  
  <xsl:template match="tei:seg[@type='cycle']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- 先頭の子要素 -->
      <xsl:variable name="first" select="*[1]"/>
      
      <xsl:if test="$first">
        <xsl:call-template name="multi-from">
          <xsl:with-param name="start" select="$first"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- [1-1] start から順に multi / 区切り記号を出力していく -->
  <xsl:template name="multi-from">
    <xsl:param name="start"/>
    
    <xsl:if test="$start">
      <xsl:choose>
        <!-- [A] 「◦」「一」そのもの：multi の外でそのまま出力 -->
        <xsl:when test="$start[self::tei:metamark[text()='◦' or text()='一']]">
          <xsl:apply-templates select="$start"/>
          
          <!-- 次の要素へ進む -->
          <xsl:variable name="next" select="$start/following-sibling::*[1]"/>
          <xsl:if test="$next">
            <xsl:call-template name="multi-from">
              <xsl:with-param name="start" select="$next"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        
        <!-- [B] それ以外：ここから「◦」「一」の直前までを 1 multi とする -->
        <xsl:otherwise>
          <!-- 次の区切り記号（◦ / 一） -->
          <xsl:variable name="next-delim"
            select="$start/following-sibling::tei:metamark[text()='◦' or text()='一'][1]"/>
          
          <seg type="multi" xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:call-template name="emit-until">
              <xsl:with-param name="node" select="$start"/>
              <xsl:with-param name="stop" select="$next-delim"/>
            </xsl:call-template>
          </seg>
          
          <!-- 区切り記号があれば、その位置から再び処理を続ける -->
          <xsl:if test="$next-delim">
            <xsl:call-template name="multi-from">
              <xsl:with-param name="start" select="$next-delim"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
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



