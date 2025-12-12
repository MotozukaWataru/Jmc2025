<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!--
    【4_technique.xslt の目的】

    3_seg_unit.xslt の出力に対して、雅楽の技法・機能情報を付与する。

    1. 掻洗（kakisukashi）の統合
       - <seg type="multi"> 直下の unit 列のうち、
         連続する 2 unit が
           * 前の unit に <metamark>┌</metamark>
           * 後ろの unit に <metamark>┐</metamark>
         を含む場合、それらを 1 つの unit に統合する。
       - 統合した unit 内に
           <seg type="technique" function="kakisukashi">
             <metamark>┌┐</metamark>
             …大譜字 g …
           </seg>
         を挿入し、┌ / ┐ 自体は削除する。

    2. unit の機能（function）の付与：tataku / hazusu
       - unit 内に小譜字（<g type="legato">）がある場合のみ対象とし、
         大譜字と同じ文字をもつ legato の有無で判定する。
           * 大譜字候補：
             - unit 直下の @type を持たない <g> の先頭
             - かきすかし本体 (<seg type="technique" function="kakisukashi">)
               内の最初の <g>
           * 小譜字（legato）の中に、大譜字と同じ文字があれば tataku、
             そうでなければ hazusu とする。
  -->
  
  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       [1] multi 内の unit 列に対する掻洗の統合
       ============================== -->
  
  <xsl:template match="tei:seg[@type='multi']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- 先頭の子要素 -->
      <xsl:variable name="first" select="*[1]"/>
      <xsl:if test="$first">
        <xsl:call-template name="process-multi-children">
          <xsl:with-param name="node" select="$first"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!--
    [1-1] multi 直下の兄弟ノードを左から順に処理
           掻洗に該当する 2 unit を 1 unit に統合する。
  -->
  <xsl:template name="process-multi-children">
    <xsl:param name="node"/>
    
    <xsl:if test="$node">
      <xsl:variable name="next" select="$node/following-sibling::*[1]"/>
      
      <xsl:choose>
        
        <!-- 掻洗判定 -->
        <xsl:when test="
          $node[self::tei:seg[@type='unit'] and tei:metamark[text()='┌']]
          and
          $next[self::tei:seg[@type='unit'] and tei:metamark[text()='┐']]
          ">
          <xsl:variable name="unit1" select="$node"/>
          <xsl:variable name="unit2" select="$next"/>
          
          <!-- unit1 / unit2 の「大譜字」（@type を持たない g）の先頭 -->
          <xsl:variable name="main1" select="$unit1/tei:g[not(@type='legato')][1]"/>
          <xsl:variable name="main2" select="$unit2/tei:g[not(@type='legato')][1]"/>
          
          <!-- unit1+unit2 の小譜字（legato）全部 -->
          <xsl:variable name="legatoAll"
            select="$unit1//tei:g[@type='legato']
            | $unit2//tei:g[@type='legato']"/>
          
          <!-- 小譜字を持つかどうか -->
          <xsl:variable name="hasLegato"
            select="count($legatoAll) &gt; 0"/>
          
          <!-- 2つの unit を 1 つの unit にまとめる -->
          <seg type="unit" xmlns="http://www.tei-c.org/ns/1.0">
            <!-- 属性は unit1 から継承 -->
            <xsl:copy-of select="$unit1/@*"/>
            
            <!-- 掻洗 unit に小譜字があれば、問答無用で hazusu -->
            <xsl:if test="$hasLegato">
              <xsl:attribute name="function">hazusu</xsl:attribute>
            </xsl:if>
            
            <!-- unit1 のうち、┌ と main1 以外をそのまま出力 -->
            <xsl:for-each select="$unit1/*">
              <xsl:if test="
                not(self::tei:metamark[text()='┌'])
                and not(generate-id() = generate-id($main1))
                ">
                <xsl:apply-templates select="."/>
              </xsl:if>
            </xsl:for-each>
            
            <!--掻洗本体 -->
            <seg type="technique" function="kakisukashi"
              xmlns="http://www.tei-c.org/ns/1.0">
              <metamark>┌┐</metamark>
              <xsl:if test="$main1">
                <xsl:apply-templates select="$main1"/>
              </xsl:if>
              <xsl:if test="$main2">
                <xsl:apply-templates select="$main2"/>
              </xsl:if>
            </seg>
            
            <!-- unit2 のうち、┐ と main2 以外をそのまま出力 -->
            <xsl:for-each select="$unit2/*">
              <xsl:if test="
                not(self::tei:metamark[text()='┐'])
                and not(generate-id() = generate-id($main2))
                ">
                <xsl:apply-templates select="."/>
              </xsl:if>
            </xsl:for-each>
          </seg>
          
          <!-- unit2 の次の兄弟ノードから処理を続ける -->
          <xsl:variable name="after" select="$unit2/following-sibling::*[1]"/>
          <xsl:if test="$after">
            <xsl:call-template name="process-multi-children">
              <xsl:with-param name="node" select="$after"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        
        <!-- 掻洗に該当しない場合は、そのまま出して次へ -->
        <xsl:otherwise>
          <xsl:apply-templates select="$node"/>
          <xsl:if test="$next">
            <xsl:call-template name="process-multi-children">
              <xsl:with-param name="node" select="$next"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:otherwise>
        
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- ==============================
       [2] unit に tataku / hazusu を付与
       ============================== -->
  
  <xsl:template match="tei:seg[@type='unit'][not(@function)]">
    
    <!-- 小譜字（legato）を含むかどうか -->
    <xsl:variable name="hasLegato" select=".//tei:g[@type='legato']"/>
    
    <!-- 大譜字候補1：unit 直下の g（@type='legato' ではない）の先頭 -->
    <xsl:variable name="headMain"
      select="tei:g[not(@type='legato')][1]"/>
    
    <!-- 大譜字候補2：掻洗本体内の g の先頭 -->
    <xsl:variable name="headKaki"
      select="tei:seg[@type='technique' and @function='kakisukashi']/tei:g[1]"/>
    
    <!-- 優先順位： 1) unit 直下の大譜字 2) かきすかし内の g -->
    <xsl:variable name="head"
      select="($headMain | $headKaki)[1]"/>
    
    <!-- head と同じ文字を持つ小譜字（legato）があるか -->
    <xsl:variable name="sameLeg"
      select=".//tei:g[@type='legato']
      [normalize-space(string())
      = normalize-space(string($head))]"/>
    
    <!-- tataku 判定 -->
    <xsl:variable name="isTataku"
      select="$hasLegato and $head and count($sameLeg) &gt;= 1"/>
    
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      
      <!-- 小譜字を含む場合だけ function を付与 -->
      <xsl:if test="$hasLegato">
        <xsl:attribute name="function">
          <xsl:choose>
            <xsl:when test="$isTataku">tataku</xsl:when>
            <xsl:otherwise>hazusu</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>



