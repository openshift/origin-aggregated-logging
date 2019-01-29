#!/usr/bin/env python

"""Custom rules implementation for elastalert monitoring."""

import re
import pickle
import logging

from elastalert.ruletypes import RuleType


class UnseenRule(RuleType):
    """
    This rule reports new logs occurance.

    Meant to be used with aggregation parameter,
    so it is not a notification, but a review of the
    error occurred in a period of time.of

    Stores information about reported logs to a file.

    Attributes:
        filename (str): filename (+path) of a pickle file
        id_template (str): log_id template
        logger (logging.Logger): rule-specific logger
        logs (dict): all processed logs, structure:
            log_id -> [log_str, ...]
        records (dict): all saved substitutions, structure:
            log_id -> [(subs, ) ...]
        regex (str): log_id extraction regex
        report_template (str): format() template for get_match_str
        required_options (str): list of required options in .yaml
    """

    required_options = set([
        'regex',
        'id_template',
        'filename',
        'report_template'
    ])

    def __init__(self, *args, **kwargs):
        """
        Create UnseenRule instance.

        Args:
            *args: arguments to pass to RuleType
            **kwargs: arguments to pass to RuleType
        """
        # initialize RuleType
        super(UnseenRule, self).__init__(*args, **kwargs)
        self.logger = logging.getLogger(self.__class__.__name__)
        # load stored data in records .pickle file
        self.filename = self.rules['filename']
        try:
            with open(self.filename, 'rb') as records_file:
                stored_data = pickle.load(records_file)
                self.records = stored_data.get('records', {})
                self.logs = stored_data.get('logs', {})
        except (IOError, EOFError):
            # or create a new file
            self.records = {}
            self.logs = {}
            with open(self.filename, 'wb') as records_file:
                pickle.dump({}, records_file)

        self.regex = self.rules['regex']
        self.id_template = self.rules['id_template']
        self.report_template = self.rules['report_template']

    def get_log_id(self, message):
        """
        Construct log id for a message.

        Args:
            message (str): log message

        Returns:
            str: Unique log identifier.
        """
        match = re.match(self.regex, message)
        if match:
            try:
                return self.id_template.format(*match.groups())
            except IndexError:
                # template contains more matchin groups than regex
                return None
        else:
            return None

    def add_data(self, data):
        """Add matches for the first occurance and collect logs.

        Args:
            data (dict): elastalert dict with a set of logs
        """
        for document in data:
            message = document['message']
            log_id = self.get_log_id(message)
            if log_id is None:
                continue  # skip unidentified messages
            # create a new logs item if needed
            if log_id not in self.logs:
                self.logger.info('New log_id occured: %s', log_id)
                # create item in logs
                self.logs[log_id] = [message]
                # match new log_id for the first time
                self.add_match(document)
            else:
                # append log w/o match
                # the log will be used for match_str construction
                self.logs[log_id].append(message)
        # store raw logs to reuse in get_match_str()
        with open(self.filename, 'wb') as records_file:
            pickle.dump({
                'records': self.records,
                'logs': self.logs
            }, records_file)

    @staticmethod
    def extract_template(messages):
        """Extract a template from a list of logs.

        Args:
            messages (list): list of strings with logs.

        Returns:
            tuple (list, list): Template and substitutions.
        """
        splitted = [message.split() for message in messages]
        template = []
        substitutions = []
        for word_variations in zip(*splitted):
            if len(set(word_variations)) == 1:
                template.append(word_variations[0])
            else:
                template.append(None)
                substitutions.append(word_variations)
        substitutions = zip(*substitutions)
        return template, substitutions

    @staticmethod
    def get_template_str(template, substitution=None):
        """Construct a log by template and substitution.

        Args:
            template (list):
                list of str/None elements
                None elements will be substituted
                everything will be concatenated
            substitution (list, optional):
                list of string (count should match the number of None elements)

        Returns:
            str: String for the current log.
        """
        index = 0
        result = []
        for word in template:
            if word is None:
                if substitution is None:
                    result.append("____")
                else:
                    result.append(substitution[index])
                    index += 1
            else:
                result.append(word)
        return " ".join(result)

    def get_match_str(self, match):
        """Construct a report for a match.

        Args:
            match (dict): elastalert match

        Returns:
            str: Report, which will be included to notification.
        """
        # extracting log_id from the match
        log_id = self.get_log_id(match['message'])
        if log_id not in self.logs:
            return "Incorrect data stored for {}:\n{}".format(
                log_id, match['message'])
        # start reporting
        logs = self.logs[log_id]
        unique_logs = list(set(logs))
        template, substitutions = self.extract_template(unique_logs)
        new_logs = []
        reported_logs = []
        # create a new records item if needed
        if log_id not in self.records:
            self.records[log_id] = []
        # identify reported/unreported logs
        for substitution in substitutions:
            # apply the substitution to the template
            log_str = self.get_template_str(template,
                                            substitution=substitution)
            if substitution not in self.records[log_id]:
                self.records[log_id].append(substitution)
                new_logs.append(log_str)
            else:
                reported_logs.append(log_str)
        # construct match string
        match_str = self.report_template.format(
            log_id=log_id,
            count=len(logs),
            unique_count=len(unique_logs),
            template=self.get_template_str(template),
            new_logs="\n".join(new_logs)
            if new_logs else "-- no logs --",
            reported_logs="\n".join(reported_logs)
            if reported_logs else "-- no logs --")
        # save update records
        self.logs[log_id] = []  # erase reported logs
        with open(self.filename, 'wb') as records_file:
            pickle.dump({
                'records': self.records,
                'logs': self.logs
            }, records_file)
        return match_str

    def add_terms_data(self, terms):
        """
        Abstract method, not used in the UnseenRule.

        Details:
        https://github.com/Yelp/elastalert/blob/master/elastalert/ruletypes.py#L74
        """
        raise NotImplementedError()
